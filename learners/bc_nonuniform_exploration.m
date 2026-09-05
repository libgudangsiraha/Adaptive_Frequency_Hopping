function [exploration, coverageScore] = ...
    bc_nonuniform_exploration( ...
        advice, expertProb, uniformFloor)
%BC_NONUNIFORM_EXPLORATION
% Context-dependent nonuniform exploration for a policy-expert class.
%
% The distribution minimizes the weighted average proxy
%
%   sum_i p_i sum_k rho_i(k)^2 / e(k)
%
% before applying the uniform probability floor.

    [K, N] = size(advice);

    expertProb = expertProb(:);

    if numel(expertProb) ~= N
        error( ...
            "Expert probability dimension is inconsistent.");
    end

    if any(~isfinite(advice), "all") ...
            || any(advice < 0, "all")

        error( ...
            "Invalid advice matrix in B+C exploration.");

    end

    if any(~isfinite(expertProb)) ...
            || any(expertProb < 0) ...
            || sum(expertProb) <= 0

        expertProb = ones(N, 1) / N;

    else

        expertProb = ...
            expertProb / sum(expertProb);

    end

    %% Weighted second moment of expert advice
    weightedSquaredAdvice = ...
        advice .^ 2 ...
        .* reshape(expertProb, 1, N);

    coverageScore = sqrt( ...
        sum(weightedSquaredAdvice, 2));

    %% Contextual nonuniform core distribution
    if any(~isfinite(coverageScore)) ...
            || any(coverageScore < 0) ...
            || sum(coverageScore) <= 0

        coreExploration = ...
            ones(K, 1) / K;

    else

        coreExploration = ...
            coverageScore ...
            / sum(coverageScore);

    end

    %% Strict positive-support floor
    mu = min(max(uniformFloor, 0), 1);

    exploration = ...
        (1 - mu) * coreExploration ...
        + mu * ones(K, 1) / K;

    exploration = ...
        exploration / sum(exploration);

end