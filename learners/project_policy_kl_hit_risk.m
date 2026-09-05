function [projectedPolicy, info] = ...
    project_policy_kl_hit_risk( ...
        inputPolicy, hitProbability, riskBudget, ...
        tolerance, maxIterations)
%PROJECT_POLICY_KL_HIT_RISK KL projection under a hit-risk budget.
%
% Solves
%   min_pi KL(pi || inputPolicy)
%   s.t.  pi in simplex, pi' * hitProbability <= riskBudget.

    if nargin < 4 || isempty(tolerance)
        tolerance = 1e-10;
    end

    if nargin < 5 || isempty(maxIterations)
        maxIterations = 80;
    end

    p0 = normalize_probability(inputPolicy);
    h = hitProbability(:);

    if numel(h) ~= numel(p0) ...
            || any(~isfinite(h)) ...
            || any(h < 0) ...
            || any(h > 1)
        error("Invalid hit-probability vector.");
    end

    if ~isscalar(riskBudget) || ~isfinite(riskBudget)
        error("Risk budget must be a finite scalar.");
    end

    riskBudget = min(max(riskBudget, 0), 1);

    preRisk = p0' * h;
    minRisk = min(h);

    info.active = false;
    info.feasible = true;
    info.lambda = 0;
    info.preRisk = preRisk;
    info.postRisk = preRisk;
    info.riskBudget = riskBudget;
    info.klDivergence = 0;
    info.budgetViolation = max(0, preRisk - riskBudget);

    if preRisk <= riskBudget + tolerance
        projectedPolicy = p0;
        info.budgetViolation = 0;
        return;
    end

    if riskBudget < minRisk - tolerance
        candidates = find(abs(h - minRisk) <= tolerance);
        projectedPolicy = zeros(size(p0));
        projectedPolicy(candidates) = 1 / numel(candidates);

        info.active = true;
        info.feasible = false;
        info.lambda = Inf;
        info.postRisk = projectedPolicy' * h;
        info.klDivergence = safe_kl(projectedPolicy, p0);
        info.budgetViolation = max(0, ...
            info.postRisk - riskBudget);
        return;
    end

    lowerLambda = 0;
    upperLambda = 1;

    [candidate, candidateRisk] = ...
        tilted_policy(p0, h, upperLambda);

    while candidateRisk > riskBudget ...
            && upperLambda < 1e12

        upperLambda = 2 * upperLambda;
        [candidate, candidateRisk] = ...
            tilted_policy(p0, h, upperLambda);
    end

    if candidateRisk > riskBudget + tolerance
        candidates = find(abs(h - minRisk) <= tolerance);
        projectedPolicy = zeros(size(p0));
        projectedPolicy(candidates) = 1 / numel(candidates);

        info.active = true;
        info.feasible = ...
            projectedPolicy' * h <= riskBudget + tolerance;
        info.lambda = Inf;
        info.postRisk = projectedPolicy' * h;
        info.klDivergence = safe_kl(projectedPolicy, p0);
        info.budgetViolation = max(0, ...
            info.postRisk - riskBudget);
        return;
    end

    projectedPolicy = candidate;

    for iteration = 1:maxIterations

        lambda = 0.5 * (lowerLambda + upperLambda);
        [candidate, candidateRisk] = ...
            tilted_policy(p0, h, lambda);

        projectedPolicy = candidate;

        if candidateRisk > riskBudget
            lowerLambda = lambda;
        else
            upperLambda = lambda;
        end

        if abs(candidateRisk - riskBudget) <= tolerance
            break;
        end
    end

    projectedPolicy = normalize_probability(projectedPolicy);

    info.active = true;
    info.lambda = upperLambda;
    info.postRisk = projectedPolicy' * h;
    info.klDivergence = safe_kl(projectedPolicy, p0);
    info.budgetViolation = max(0, ...
        info.postRisk - riskBudget);

end


function [policy, risk] = tilted_policy(p0, h, lambda)

    shiftedRisk = h - min(h);
    logWeight = log(max(p0, realmin)) ...
        - lambda .* shiftedRisk;

    logWeight = logWeight - max(logWeight);
    policy = exp(logWeight);
    policy = normalize_probability(policy);
    risk = policy' * h;

end


function value = safe_kl(p, q)

    mask = p > 0;
    value = sum(p(mask) .* log( ...
        p(mask) ./ max(q(mask), realmin)));

end


function p = normalize_probability(p)

    p = p(:);

    if any(~isfinite(p)) || any(p < 0) || sum(p) <= 0
        p = ones(numel(p), 1) / numel(p);
    else
        p = p / sum(p);
    end

end
