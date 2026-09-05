function [exploration, tiltWeight] = ...
    bc_detect_exploration( ...
        learner, baseExploration, q_t)
%BC_DETECT_EXPLORATION
% Prediction-aware tilt of the shared contextual exploration policy.
%
%   e_q(k) proportional to
%       e_0(k) * [q_t(k) + epsilon]^(-nu).

    K = learner.K;

    baseExploration = baseExploration(:);
    q_t = q_t(:);

    if numel(baseExploration) ~= K ...
            || numel(q_t) ~= K

        error( ...
            "Invalid dimension in B+C detect exploration.");

    end

    if any(~isfinite(baseExploration)) ...
            || any(baseExploration <= 0) ...
            || sum(baseExploration) <= 0

        baseExploration = ones(K, 1) / K;
    else
        baseExploration = ...
            baseExploration / sum(baseExploration);
    end

    if any(~isfinite(q_t)) ...
            || any(q_t < 0) ...
            || sum(q_t) <= 0

        q_t = ones(K, 1) / K;
    else
        q_t = q_t / sum(q_t);
    end

    tiltWeight = ...
        (q_t + learner.exploreEpsilon) ...
        .^ (-learner.detectNu);

    rawExploration = ...
        baseExploration .* tiltWeight;

    if any(~isfinite(rawExploration)) ...
            || any(rawExploration < 0) ...
            || sum(rawExploration) <= 0

        exploration = baseExploration;
    else
        exploration = ...
            rawExploration / sum(rawExploration);
    end

end
