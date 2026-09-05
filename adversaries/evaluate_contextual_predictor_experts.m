function [advice, aux] = ...
    evaluate_contextual_predictor_experts( ...
        X_t, actionHistory, t, bank)
%EVALUATE_CONTEXTUAL_PREDICTOR_EXPERTS Vectorized predictor evaluation.

    K = bank.K;
    N = bank.numExperts;
    features = X_t(bank.featureRows, :);
    features = min(max(features, 0), 1);
    advice = zeros(K, N);

    uniformIndex = find(bank.type == "uniform");
    advice(:, uniformIndex) = 1 / K;

    uniqueWindows = unique(bank.historyWindow(bank.historyWindow > 0));
    historyNormalized = zeros(K, numel(uniqueWindows));
    historyProbability = cell(numel(uniqueWindows), 1);

    for index = 1:numel(uniqueWindows)
        probability = local_history_distribution( ...
            actionHistory, t, K, uniqueWindows(index), bank.historyAlpha);
        historyProbability{index} = probability;
        historyNormalized(:, index) = probability ./ max(probability);
    end

    contextIndex = find(bank.type == "context");
    if ~isempty(contextIndex)
        scores = features' * bank.contextWeights(:, contextIndex);
        advice(:, contextIndex) = column_softmax( ...
            scores, bank.temperature(contextIndex));
    end

    historyIndex = find(bank.type == "history");
    if ~isempty(historyIndex)
        scores = cached_history_matrix( ...
            bank.historyWindow(historyIndex), ...
            uniqueWindows, historyNormalized);
        advice(:, historyIndex) = column_softmax( ...
            scores, bank.temperature(historyIndex));
    end

    hybridIndex = find(bank.type == "hybrid");
    if ~isempty(hybridIndex)
        contextScores = ...
            features' * bank.contextWeights(:, hybridIndex);
        historyScores = cached_history_matrix( ...
            bank.historyWindow(hybridIndex), ...
            uniqueWindows, historyNormalized);
        beta = bank.historyMix(hybridIndex)';
        scores = contextScores .* (1 - beta) + historyScores .* beta;
        advice(:, hybridIndex) = column_softmax( ...
            scores, bank.temperature(hybridIndex));
    end

    if max(abs(sum(advice, 1) - 1)) > 1e-10 ...
            || any(~isfinite(advice), "all") ...
            || any(advice < 0, "all")
        error("Predictor expert advice is invalid.");
    end

    aux.features = features;
    aux.uniqueWindows = uniqueWindows;
    aux.historyProbability = historyProbability;

end


function matrix = cached_history_matrix(windows, uniqueWindows, cache)

    matrix = zeros(size(cache, 1), numel(windows));

    for index = 1:numel(windows)
        if isinf(windows(index))
            cacheIndex = find(isinf(uniqueWindows), 1, "first");
        else
            cacheIndex = find(uniqueWindows == windows(index), 1, "first");
        end
        matrix(:, index) = cache(:, cacheIndex);
    end

end


function probability = column_softmax(scores, temperatures)

    scaled = scores ./ max(temperatures(:)', 1e-8);
    scaled = scaled - max(scaled, [], 1);
    probability = exp(scaled);
    denominator = sum(probability, 1);
    invalid = ~isfinite(denominator) | denominator <= 0;
    denominator(invalid) = 1;
    probability = probability ./ denominator;
    probability(:, invalid) = 1 / size(scores, 1);

end


function probability = local_history_distribution( ...
    actionHistory, t, K, W, alpha)

    if t <= 1
        pastActions = zeros(0, 1);
    else
        pastActions = actionHistory(1:(t - 1));
        pastActions = pastActions(pastActions >= 1 & pastActions <= K);
    end

    if isfinite(W) && numel(pastActions) > W
        pastActions = pastActions((end - W + 1):end);
    end

    counts = zeros(K, 1);
    if ~isempty(pastActions)
        counts = accumarray(pastActions(:), 1, [K, 1], @sum, 0);
    end

    probability = ...
        (counts + alpha) ./ (numel(pastActions) + K * alpha);

end
