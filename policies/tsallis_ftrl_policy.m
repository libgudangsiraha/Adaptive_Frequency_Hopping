function p = tsallis_ftrl_policy(cumulativeLoss, eta)
%TSALLIS_FTRL_POLICY Tsallis-FTRL distribution for alpha = 1/2.
%
% Solves:
%   min_{p in Delta_K}
%       <cumulativeLoss, p>
%       + (1 / eta) * 2 * (1 - sum_k sqrt(p_k))
%
% KKT solution:
%   p_k = 1 / (eta^2 * (L_k - z)^2),
% where z < min_k L_k is chosen so that sum_k p_k = 1.

    L = cumulativeLoss(:);
    K = numel(L);

    if K < 1
        error("cumulativeLoss must be nonempty.");
    end

    if ~isfinite(eta) || eta <= 0
        error("eta must be finite and positive.");
    end

    if any(~isfinite(L))
        error("cumulativeLoss contains nonfinite values.");
    end

    %% Shift losses to improve numerical stability
    minLoss = min(L);
    shiftedLoss = L - minLoss;

    % Let delta = minLoss - z > 0.
    % Solve:
    %   sum 1 / [eta^2 * (shiftedLoss_k + delta)^2] = 1.

    lower = 1e-12;
    upper = max(1, sqrt(K) / eta);

    while normalization_sum(shiftedLoss, eta, upper) > 1
        upper = 2 * upper;

        if upper > 1e16
            p = ones(K, 1) / K;
            return;
        end
    end

    %% Bisection
    for iter = 1:80

        midpoint = 0.5 * (lower + upper);
        currentSum = normalization_sum( ...
            shiftedLoss, eta, midpoint);

        if currentSum > 1
            lower = midpoint;
        else
            upper = midpoint;
        end

    end

    delta = 0.5 * (lower + upper);

    denominator = eta^2 ...
        .* (shiftedLoss + delta).^2;

    p = 1 ./ denominator;

    %% Numerical normalization
    if any(~isfinite(p)) || any(p < 0) || sum(p) <= 0
        p = ones(K, 1) / K;
    else
        p = p / sum(p);
    end

end


function value = normalization_sum(shiftedLoss, eta, delta)

    denominator = eta^2 ...
        .* (shiftedLoss + delta).^2;

    value = sum(1 ./ denominator);

end