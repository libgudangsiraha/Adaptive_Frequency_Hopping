function inclusionProbability = ...
    attack_inclusion_probability(q_t, M_jam)
%ATTACK_INCLUSION_PROBABILITY Fixed-budget marginal attack probabilities.
%
% Given a public predictor distribution q_t and an integer attack budget M,
% construct h_t in [0,1]^K such that
%
%   h_t(k) = min(1, lambda * q_t(k)),
%   sum_k h_t(k) = M.
%
% The scalar lambda is found by bisection.  h_t(k) is the marginal
% probability that channel k belongs to the sampled attack set.

    q_t = q_t(:);
    K = numel(q_t);

    if K < 1
        error("Attack probability requires at least one channel.");
    end

    if any(~isfinite(q_t)) ...
            || any(q_t < 0) ...
            || sum(q_t) <= 0

        q_t = ones(K, 1) / K;
    else
        q_t = q_t / sum(q_t);
    end

    M = min(max(round(M_jam), 0), K);

    if M == 0
        inclusionProbability = zeros(K, 1);
        return;
    elseif M == K
        inclusionProbability = ones(K, 1);
        return;
    end

    lowerLambda = 0;
    upperLambda = 1;

    % Expand the upper bracket until the required budget is reachable.
    while sum(min(1, upperLambda .* q_t)) < M
        upperLambda = 2 * upperLambda;

        if ~isfinite(upperLambda) || upperLambda > 1e16
            error("Could not bracket attack-inclusion multiplier.");
        end
    end

    for iteration = 1:100
        lambda = 0.5 * (lowerLambda + upperLambda);
        candidate = min(1, lambda .* q_t);

        if sum(candidate) < M
            lowerLambda = lambda;
        else
            upperLambda = lambda;
        end
    end

    inclusionProbability = min(1, upperLambda .* q_t);

    % Remove the tiny residual left by floating-point bisection while
    % preserving box constraints.
    residual = M - sum(inclusionProbability);

    if residual > 0
        available = find(inclusionProbability < 1 - 1e-14);

        for index = 1:numel(available)
            arm = available(index);
            increment = min( ...
                residual, 1 - inclusionProbability(arm));
            inclusionProbability(arm) = ...
                inclusionProbability(arm) + increment;
            residual = residual - increment;

            if residual <= 1e-13
                break;
            end
        end

    elseif residual < 0
        available = find(inclusionProbability > 1e-14);

        for index = 1:numel(available)
            arm = available(index);
            decrement = min( ...
                -residual, inclusionProbability(arm));
            inclusionProbability(arm) = ...
                inclusionProbability(arm) - decrement;
            residual = residual + decrement;

            if residual >= -1e-13
                break;
            end
        end
    end

    inclusionProbability = min(max( ...
        inclusionProbability, 0), 1);

    if abs(sum(inclusionProbability) - M) > 1e-9
        error("Attack inclusion probabilities do not match the budget.");
    end

end
