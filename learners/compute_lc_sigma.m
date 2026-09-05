function [Sigma, SigmaInv, rcondValue] = ...
    compute_lc_sigma(learner, t)
%COMPUTE_LC_SIGMA Approximate LC policy-induced covariance.
%
% contextPool:
%   d x K x M independent context samples.

    contextPool = learner.contextPool;

    [d, K, M] = size(contextPool);

    if d ~= learner.featureDim
        error("Context-pool feature dimension mismatch.");
    end

    if K ~= learner.K
        error("Context-pool arm count mismatch.");
    end

    if M < 1
        error("LC context pool is empty.");
    end

    Sigma = zeros(d, d);

    for m = 1:M

        X_m = contextPool(:, :, m);

        [pi_m, ~, ~, ~] = ...
            lc_policy_from_context(learner, X_m, t);

        % Sum_k pi(k) phi_k phi_k'
        weightedFeatures = ...
            X_m .* reshape(pi_m', 1, K);

        Sigma = Sigma ...
            + weightedFeatures * X_m';

    end

    Sigma = Sigma / M;

    %% Symmetrize against numerical drift
    Sigma = 0.5 * (Sigma + Sigma');

    %% Practical regularization for finite-pool approximation
    SigmaRegularized = ...
        Sigma + learner.sigmaRidge * eye(d);

    rcondValue = rcond(SigmaRegularized);

    if ~isfinite(rcondValue)
        rcondValue = 0;
    end

    SigmaInv = pinv(SigmaRegularized);

    if any(~isfinite(SigmaInv), "all")
        error("LC covariance inverse became nonfinite.");
    end

end