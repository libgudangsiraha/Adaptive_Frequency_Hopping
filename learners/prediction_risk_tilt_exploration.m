function [exploration, tiltWeight] = ...
    prediction_risk_tilt_exploration( ...
        learner, baseExploration, riskVector)
%PREDICTION_RISK_TILT_EXPLORATION Tilt exploration away from hit risk.
%
% Unlike q_t, a fixed-budget inclusion vector sums to M rather than one.
% Therefore this function deliberately does not renormalize riskVector.

    K = learner.K;
    baseExploration = baseExploration(:);
    riskVector = riskVector(:);

    if numel(baseExploration) ~= K ...
            || numel(riskVector) ~= K
        error("Invalid dimension in prediction-risk exploration tilt.");
    end

    if any(~isfinite(baseExploration)) ...
            || any(baseExploration <= 0) ...
            || sum(baseExploration) <= 0
        baseExploration = ones(K, 1) / K;
    else
        baseExploration = baseExploration / sum(baseExploration);
    end

    if any(~isfinite(riskVector)) ...
            || any(riskVector < 0) ...
            || any(riskVector > 1)
        error("Invalid prediction-risk vector.");
    end

    tiltWeight = ...
        (riskVector + learner.exploreEpsilon) ...
        .^ (-learner.detectNu);

    rawExploration = baseExploration .* tiltWeight;

    if any(~isfinite(rawExploration)) ...
            || any(rawExploration < 0) ...
            || sum(rawExploration) <= 0
        exploration = baseExploration;
    else
        exploration = rawExploration / sum(rawExploration);
    end

end
