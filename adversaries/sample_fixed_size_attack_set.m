function jammed = sample_fixed_size_attack_set(inclusionProbability)
%SAMPLE_FIXED_SIZE_ATTACK_SET Dependent rounding with exact cardinality.
%
% Input h must satisfy 0 <= h_k <= 1 and sum(h) = M for an integer M.
% The output is a binary vector with exactly M ones and marginal
% probability E[jammed(k)] = h_k (up to numerical tolerance).

    x = inclusionProbability(:);
    K = numel(x);

    if any(~isfinite(x)) ...
            || any(x < -1e-12) ...
            || any(x > 1 + 1e-12)
        error("Invalid attack inclusion probability vector.");
    end

    x = min(max(x, 0), 1);
    M = round(sum(x));

    if abs(sum(x) - M) > 1e-8
        error("Inclusion probabilities must sum to an integer budget.");
    end

    tolerance = 1e-12;

    while true
        fractional = find( ...
            x > tolerance & x < 1 - tolerance);

        if numel(fractional) < 2
            break;
        end

        i = fractional(1);
        j = fractional(2);

        alpha = min(1 - x(i), x(j));
        beta = min(x(i), 1 - x(j));

        denominator = alpha + beta;

        if denominator <= tolerance
            break;
        end

        % This probability makes the expected change of each coordinate
        % exactly zero, hence preserving the requested marginals.
        if rand < beta / denominator
            x(i) = x(i) + alpha;
            x(j) = x(j) - alpha;
        else
            x(i) = x(i) - beta;
            x(j) = x(j) + beta;
        end
    end

    fractional = find( ...
        x > tolerance & x < 1 - tolerance);

    if numel(fractional) == 1
        i = fractional(1);
        integerOthers = round(x);
        integerOthers(i) = 0;
        x(i) = M - sum(integerOthers);
    elseif numel(fractional) > 1
        error("Dependent rounding did not terminate.");
    end

    jammed = double(x >= 0.5);

    if numel(jammed) ~= K || sum(jammed) ~= M
        error("Fixed-size attack sampling failed.");
    end

end
