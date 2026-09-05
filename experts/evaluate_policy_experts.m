function advice = evaluate_policy_experts(X_t, expertBank)
%EVALUATE_POLICY_EXPERTS Evaluate all fixed contextual experts.
%
% Inputs:
%   X_t        - d x K context matrix
%   expertBank - output of build_generic_experts
%
% Output:
%   advice     - K x N matrix
%                each column is one expert's action distribution

    K = expertBank.K;
    N = expertBank.numExperts;

    if size(X_t, 2) ~= K
        error( ...
            "X_t contains %d arms, but expert bank expects %d.", ...
            size(X_t, 2), K);
    end

    if max(expertBank.featureRows) > size(X_t, 1)
        error("Expert feature row exceeds X_t dimension.");
    end

    features = X_t(expertBank.featureRows, :);

    if any(~isfinite(features), "all")
        error("Context supplied to experts contains nonfinite values.");
    end

    %% Optional per-round feature normalization
    if expertBank.normalizePerRound
        features = normalize_feature_rows(features);
    end

    advice = zeros(K, N);

    for i = 1:N

        if expertBank.isUniform(i)

            advice(:, i) = ones(K, 1) / K;
            continue;

        end

        w = expertBank.weights(:, i);
        tau = expertBank.temperature(i);

        if ~isfinite(tau) || tau <= 0
            error("Expert %d has an invalid temperature.", i);
        end

        scores = w' * features;
        scaledScores = scores(:) / tau;

        % Numerically stable softmax
        scaledScores = scaledScores - max(scaledScores);
        probabilities = exp(scaledScores);

        totalProbability = sum(probabilities);

        if ~isfinite(totalProbability) || totalProbability <= 0
            advice(:, i) = ones(K, 1) / K;
        else
            advice(:, i) = probabilities / totalProbability;
        end

    end

    %% Final safety normalization
    columnSums = sum(advice, 1);

    if any(~isfinite(advice), "all") ...
            || any(advice < 0, "all") ...
            || any(columnSums <= 0)

        error("Invalid expert advice matrix.");

    end

    advice = advice ./ columnSums;

end


function features = normalize_feature_rows(features)

    for row = 1:size(features, 1)

        rowValues = features(row, :);

        rowMin = min(rowValues);
        rowMax = max(rowValues);
        rowRange = rowMax - rowMin;

        if rowRange > 1e-12
            features(row, :) = ...
                (rowValues - rowMin) / rowRange;
        else
            features(row, :) = zeros(size(rowValues));
        end

    end

end