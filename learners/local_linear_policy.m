function [policy, aux] = local_linear_policy(learner, X_t, t)
%LOCAL_LINEAR_POLICY Contextual policy from piecewise local ridge models.

    features = X_t(learner.featureRows, :);
    features = min(max(features, 0), 1);

    K = learner.K;
    predictedLoss = zeros(K, 1);
    uncertainty = zeros(K, 1);
    cellIndex = zeros(K, 1);
    phiMatrix = zeros(learner.parameterDim, K);

    for arm = 1:K
        x = features(:, arm);
        phi = [1; x];
        cellId = local_cell_index(x, learner.localBins);

        [A, b] = decayed_cell_statistics( ...
            learner, cellId, t);

        theta = A \ b;
        prediction = phi' * theta;
        prediction = min(max(prediction, 0), 1);

        variance = phi' * (A \ phi);
        variance = max(variance, 0);

        predictedLoss(arm) = prediction;
        uncertainty(arm) = sqrt(variance);
        cellIndex(arm) = cellId;
        phiMatrix(:, arm) = phi;
    end

    optimism = ...
        learner.ucbScale ...
        .* sqrt(log(max(t, 2))) ...
        .* uncertainty;

    optimisticLoss = predictedLoss - optimism;

    temperature = max( ...
        learner.minTemperature, ...
        learner.temperature ...
        / max(log(max(t, 2)), 1)^learner.temperatureDecay);

    logWeight = -optimisticLoss / max(temperature, 1e-8);
    logWeight = logWeight - max(logWeight);

    policy = exp(logWeight);

    if any(~isfinite(policy)) || sum(policy) <= 0
        policy = ones(K, 1) / K;
    else
        policy = policy / sum(policy);
    end

    aux.policy = policy;
    aux.predictedLoss = predictedLoss;
    aux.uncertainty = uncertainty;
    aux.cellIndex = cellIndex;
    aux.phiMatrix = phiMatrix;
    aux.temperature = temperature;

end


function cellId = local_cell_index(x, bins)

    dimension = numel(bins);
    subscript = ones(1, dimension);

    for index = 1:dimension
        value = min(max(x(index), 0), 1);
        subscript(index) = min( ...
            floor(value * bins(index)) + 1, ...
            bins(index));
    end

    multiplier = [1, cumprod(bins(1:end-1))];
    cellId = 1 + sum((subscript - 1) .* multiplier);

end


function [A, b] = decayed_cell_statistics(learner, cellId, t)

    lastUpdate = learner.lastCellUpdate(cellId);

    if lastUpdate <= 0
        decay = 1;
    else
        decay = learner.forgetting ^ max(t - lastUpdate, 0);
    end

    A = learner.ridge * eye(learner.parameterDim) ...
        + decay .* learner.gramData(:, :, cellId);

    b = decay .* learner.targetData(:, cellId);

end
