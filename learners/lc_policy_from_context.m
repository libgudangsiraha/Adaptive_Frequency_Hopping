function [pi_t, baseProb, eta_t, gamma_t] = ...
    lc_policy_from_context(learner, X_t, t)
%LC_POLICY_FROM_CONTEXT Evaluate LC-Tsallis-INF policy at one context.
%
% X_t:
%   d x K arm-dependent feature matrix.

    if size(X_t, 1) ~= learner.featureDim
        error("LC feature dimension mismatch.");
    end

    if size(X_t, 2) ~= learner.K
        error("LC number of arms mismatch.");
    end

    %% Learning-rate schedule
    eta_t = learner.etaScale / sqrt(max(t, 1));

    %% Cumulative estimated loss at current context
    cumulativeLoss = X_t' * learner.cumThetaHat;

    %% Tsallis-FTRL base policy
    baseProb = tsallis_ftrl_policy( ...
        cumulativeLoss, eta_t);

    %% Paper-inspired decaying exploration
    %
    % Since eta_t = O(t^{-1/2}),
    % sqrt(eta_t) = O(t^{-1/4}).
    gamma_t = min( ...
        learner.gammaMax, ...
        learner.gammaScale * sqrt(eta_t));

    exploration = ones(learner.K, 1) / learner.K;

    pi_t = ...
        (1 - gamma_t) * baseProb ...
        + gamma_t * exploration;

    pi_t = pi_t / sum(pi_t);

end