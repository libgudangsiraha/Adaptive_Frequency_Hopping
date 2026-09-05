function [pi_t, aux, learner] = dynamic_pact_select( ...
    learner, X_t, q_t, t)
%DYNAMIC_PACT_SELECT Dynamic master over adaptive LC and local learners.
%
% The communication channel uses bandit feedback.  The prediction-risk
% channel is full information and may use either q-overlap or the exact
% fixed-budget attack-set inclusion probability.

    switch learner.forceBase
        case "lc"
            [lcPolicy, lcAux, learner.lcBase] = ...
                dynamic_lc_base_select(learner.lcBase, X_t, t);
            localPolicy = ones(learner.K, 1) / learner.K;
            localAux = struct();

        case "local"
            lcPolicy = ones(learner.K, 1) / learner.K;
            lcAux = struct();
            [localPolicy, localAux] = ...
                local_linear_policy(learner.localBase, X_t, t);

        case "none"
            [lcPolicy, lcAux, learner.lcBase] = ...
                dynamic_lc_base_select(learner.lcBase, X_t, t);
            [localPolicy, localAux] = ...
                local_linear_policy(learner.localBase, X_t, t);

        otherwise
            error("Unknown dynamic forceBase value: %s", ...
                learner.forceBase);
    end

    basePolicies = [lcPolicy, localPolicy];

    if any(~isfinite(basePolicies), "all") ...
            || any(basePolicies < 0, "all")
        error("Dynamic PACT base policy became invalid.");
    end

    [rawRisk, normalizedRisk, riskVector, riskReference] = ...
        dynamic_pact_prediction_risk( ...
            basePolicies, q_t, learner);

    eta_t = learner.masterEtaScale / sqrt(max(t, 1));
    effectiveLoss = learner.masterCumCommLoss;

    if learner.useNewPredictionLoss
        effectiveLoss = effectiveLoss ...
            + learner.detectBeta .* ( ...
                learner.masterCumPredictionRisk ...
                + learner.currentRiskWeight .* normalizedRisk);
    end

    masterProb = tsallis_ftrl_policy(effectiveLoss, eta_t);

    switch learner.forceBase
        case "lc"
            masterProb = [1; 0];

        case "local"
            masterProb = [0; 1];

        case "none"
            anchor = min(1, max(0, ...
                learner.lcAnchorFloor ...
                + learner.lcAnchorScale / sqrt(max(t, 1))));

            masterProb = ...
                (1 - anchor) .* masterProb ...
                + anchor .* [1; 0];

            masterProb = masterProb / sum(masterProb);

        otherwise
            error("Unknown dynamic forceBase value: %s", ...
                learner.forceBase);
    end

    baseProb = normalize_probability( ...
        basePolicies * masterProb);

    [baseExploration, coverageScore] = ...
        bc_nonuniform_exploration( ...
            basePolicies, masterProb, learner.exploreUniformFloor);

    if learner.usePredictionExploration
        [exploration, tiltWeight] = ...
            prediction_risk_tilt_exploration( ...
                learner, baseExploration, riskVector);
    else
        exploration = baseExploration;
        tiltWeight = ones(learner.K, 1);
    end

    gamma_t = min( ...
        learner.gammaMax, ...
        learner.gammaScale / sqrt(max(t, 1)));

    pi_t = ...
        (1 - gamma_t) .* baseProb ...
        + gamma_t .* exploration;

    pi_t = normalize_probability(pi_t);

    preProjectionPolicy = pi_t;

    projectionInfo.active = false;
    projectionInfo.feasible = true;
    projectionInfo.lambda = 0;
    projectionInfo.preRisk = pi_t' * riskVector;
    projectionInfo.postRisk = projectionInfo.preRisk;
    projectionInfo.riskBudget = NaN;
    projectionInfo.klDivergence = 0;
    projectionInfo.budgetViolation = 0;

    if learner.useRiskProjection

        [pi_t, projectionInfo] = ...
            project_policy_kl_hit_risk( ...
                preProjectionPolicy, ...
                riskVector, ...
                learner.riskProjectionBudget, ...
                learner.riskProjectionTolerance, ...
                learner.riskProjectionMaxIterations);

        pi_t = normalize_probability(pi_t);
    end

    learner.lastRiskProjectionActive = ...
        projectionInfo.active;
    learner.lastRiskProjectionLambda = ...
        projectionInfo.lambda;
    learner.lastRiskProjectionKl = ...
        projectionInfo.klDivergence;
    learner.lastPreProjectionRisk = ...
        projectionInfo.preRisk;
    learner.lastPostProjectionRisk = ...
        projectionInfo.postRisk;
    learner.lastRiskProjectionViolation = ...
        projectionInfo.budgetViolation;

    learner.lastMasterProb = masterProb;
    learner.lastBasePolicies = basePolicies;
    learner.lastEta = eta_t;
    learner.lastGamma = gamma_t;
    learner.lastCurrentBaseRiskRaw = rawRisk;
    learner.lastCurrentBaseRiskNormalized = normalizedRisk;
    learner.lastEffectiveMasterLoss = effectiveLoss;
    learner.lastPredictionRiskVector = riskVector;
    learner.lastPredictionRiskReference = riskReference;

    aux.basePolicies = basePolicies;
    aux.masterProb = masterProb;
    aux.baseProb = baseProb;
    aux.baseExploration = baseExploration;
    aux.exploration = exploration;
    aux.coverageScore = coverageScore;
    aux.tiltWeight = tiltWeight;
    aux.gamma = gamma_t;
    aux.eta = eta_t;
    aux.currentBaseRiskRaw = rawRisk;
    aux.currentBaseRiskNormalized = normalizedRisk;
    aux.effectiveMasterLoss = effectiveLoss;
    aux.predictionRiskVector = riskVector;
    aux.predictionRiskReference = riskReference;
    aux.predictionRiskMode = learner.predictionRiskMode;

    aux.preProjectionPolicy = preProjectionPolicy;
    aux.riskProjectionActive = projectionInfo.active;
    aux.riskProjectionFeasible = projectionInfo.feasible;
    aux.riskProjectionLambda = projectionInfo.lambda;
    aux.riskProjectionBudget = projectionInfo.riskBudget;
    aux.riskProjectionKl = projectionInfo.klDivergence;
    aux.preProjectionHitRisk = projectionInfo.preRisk;
    aux.postProjectionHitRisk = projectionInfo.postRisk;
    aux.riskProjectionViolation = ...
        projectionInfo.budgetViolation;

    aux.lcAux = lcAux;
    aux.localAux = localAux;

end


function p = normalize_probability(p)

    p = p(:);

    if any(~isfinite(p)) || any(p < 0) || sum(p) <= 0
        p = ones(numel(p), 1) / numel(p);
    else
        p = p / sum(p);
    end

end
