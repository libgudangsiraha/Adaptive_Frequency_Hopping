function learner = dynamic_pact_update( ...
    learner, X_t, feedback, aux, t)
%DYNAMIC_PACT_UPDATE Update master and both adaptive base learners.

    a_t = feedback.action;
    reward_t = min(max(feedback.reward, 0), 1);
    masterPolicy = feedback.pi(:);
    q_t = feedback.q(:);
    basePolicies = aux.basePolicies;

    [rawRisk, normalizedRisk, riskVector, riskReference] = ...
        dynamic_pact_prediction_risk( ...
            basePolicies, q_t, learner);

    if max(abs(rawRisk - aux.currentBaseRiskRaw)) > 1e-10
        error("Dynamic PACT selection/update risk mismatch.");
    end

    if max(abs( ...
            riskVector - aux.predictionRiskVector)) > 1e-10
        error("Dynamic PACT risk-vector mismatch.");
    end

    if abs(riskReference - aux.predictionRiskReference) > 1e-12
        error("Dynamic PACT risk-reference mismatch.");
    end

    observedLoss = 1 - reward_t;
    lossHat = zeros(learner.K, 1);
    lossHat(a_t) = ...
        observedLoss / max(masterPolicy(a_t), 1e-12);

    estimatedBaseLoss = basePolicies' * lossHat;

    if any(~isfinite(estimatedBaseLoss))
        error("Dynamic PACT master loss became nonfinite.");
    end

    learner.masterCumCommLoss = ...
        learner.masterCumCommLoss + estimatedBaseLoss;

    learner.masterCumPredictionRisk = ...
        learner.masterCumPredictionRisk + normalizedRisk;

    learner.cumulativeExpectedBaseRisk = ...
        learner.cumulativeExpectedBaseRisk + rawRisk;

    if learner.forceBase ~= "local"
        learner.lcBase = dynamic_lc_base_update( ...
            learner.lcBase, X_t, feedback, aux.lcAux);
    end

    if learner.forceBase ~= "lc"
        learner.localBase = local_linear_update( ...
            learner.localBase, feedback, aux.localAux, t);
    end

    learner.maxEstimatedMasterLoss = max( ...
        learner.maxEstimatedMasterLoss, ...
        max(estimatedBaseLoss));

    learner.maxAbsPredictionRiskSignal = max( ...
        learner.maxAbsPredictionRiskSignal, ...
        max(abs(normalizedRisk)));

    learner.lastPredictionRiskVector = riskVector;
    learner.lastPredictionRiskReference = riskReference;
    learner.numUpdates = learner.numUpdates + 1;

end
