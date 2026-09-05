function learner = dynamic_lc_base_update( ...
    learner, X_t, feedback, aux)
%DYNAMIC_LC_BASE_UPDATE Off-policy LC update under a master action.
%
% The action is drawn from the master policy pi_t, while this base learner
% recommends rho_t. The importance ratio rho_t(A_t)/pi_t(A_t) converts the
% observed loss into an update targeted at the LC base policy.

    a_t = feedback.action;
    observedLoss = 1 - min(max(feedback.reward, 0), 1);

    masterPolicy = feedback.pi(:);
    basePolicy = aux.policy(:);

    denominator = max(masterPolicy(a_t), 1e-12);
    ratio = basePolicy(a_t) / denominator;
    ratio = min(max(ratio, 0), learner.offPolicyRatioCap);

    phiSelected = X_t(:, a_t);
    SigmaInv = aux.SigmaInv;

    thetaHat = ...
        SigmaInv * phiSelected * observedLoss * ratio;

    if any(~isfinite(thetaHat))
        error("Dynamic LC theta estimator became nonfinite.");
    end

    learner.cumThetaHat = learner.cumThetaHat + thetaHat;
    learner.lastThetaHat = thetaHat;
    learner.maxThetaHatNorm = max( ...
        learner.maxThetaHatNorm, norm(thetaHat));
    learner.maxOffPolicyRatio = max( ...
        learner.maxOffPolicyRatio, ratio);
    learner.numUpdates = learner.numUpdates + 1;

end
