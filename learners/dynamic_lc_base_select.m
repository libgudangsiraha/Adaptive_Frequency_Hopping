function [policy, aux, learner] = dynamic_lc_base_select( ...
    learner, X_t, t)
%DYNAMIC_LC_BASE_SELECT LC-Tsallis-INF policy for a dynamic master.
%
% The returned policy is exactly the online LC policy. The covariance
% estimate is updated from the LC policy's own online context buffer.

    [policy, baseProb, eta_t, gamma_t] = ...
        lc_policy_from_context(learner, X_t, t);

    if learner.covarianceMode ~= "online"
        error("Dynamic LC base must use online covariance mode.");
    end

    learner.contextPool(:, :, end + 1) = X_t;

    if size(learner.contextPool, 3) > learner.onlineBufferSize
        learner.contextPool = learner.contextPool( ...
            :, :, (end - learner.onlineBufferSize + 1):end);
    end

    needSigmaUpdate = ...
        isempty(learner.sigmaInvCache) ...
        || (t - learner.lastSigmaUpdate >= learner.sigmaUpdatePeriod);

    if needSigmaUpdate
        [Sigma, SigmaInv, sigmaRcond] = ...
            compute_lc_sigma(learner, t);

        learner.sigmaCache = Sigma;
        learner.sigmaInvCache = SigmaInv;
        learner.sigmaRcond = sigmaRcond;
        learner.lastSigmaUpdate = t;
    end

    aux.policy = policy;
    aux.baseProb = baseProb;
    aux.eta = eta_t;
    aux.gamma = gamma_t;
    aux.Sigma = learner.sigmaCache;
    aux.SigmaInv = learner.sigmaInvCache;
    aux.sigmaRcond = learner.sigmaRcond;

end
