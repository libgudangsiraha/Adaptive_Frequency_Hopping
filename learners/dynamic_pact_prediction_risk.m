function [rawRisk, normalizedRisk, riskVector, reference] = ...
    dynamic_pact_prediction_risk(basePolicies, q_t, learner)
%DYNAMIC_PACT_PREDICTION_RISK Risk signal used by the dynamic master.
%
% Modes:
%   q_overlap       : risk vector q_t, uniform reference 1/K.
%   hit_probability : fixed-budget inclusion vector h_t, reference M/K.

    [K, ~] = size(basePolicies);
    q_t = normalize_probability(q_t, K);

    mode = lower(string(learner.predictionRiskMode));

    switch mode
        case "q_overlap"
            riskVector = q_t;
            reference = 1 / K;

        case "hit_probability"
            riskVector = attack_inclusion_probability( ...
                q_t, learner.MJam);
            reference = min(max(learner.MJam, 0), K) / K;

        otherwise
            error("Unknown dynamic prediction-risk mode: %s", mode);
    end

    rawRisk = basePolicies' * riskVector;
    rawRisk = min(max(rawRisk, 0), 1);

    if reference >= 1 - 1e-12
        normalizedRisk = zeros(size(rawRisk));
    else
        normalizedRisk = ...
            (rawRisk - reference) / (1 - reference);
    end

end


function probability = normalize_probability(probability, K)

    probability = probability(:);

    if numel(probability) ~= K
        error("Invalid q_t dimension in dynamic risk computation.");
    end

    if any(~isfinite(probability)) ...
            || any(probability < 0) ...
            || sum(probability) <= 0
        probability = ones(K, 1) / K;
    else
        probability = probability / sum(probability);
    end

end
