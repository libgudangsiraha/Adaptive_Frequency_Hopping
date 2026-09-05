function results = run_single_pair( ...
    cfgRun, env, learnerType, adversaryType)
%RUN_SINGLE_PAIR One learner-adversary communication simulation.
%
% Timeline:
%   X_t -> public q_t -> hidden attack realization -> pi_t -> A_t
%       -> communication outcome -> learner/adversary updates.

    T = cfgRun.T;
    K = cfgRun.K;

    learnerCfg = get_learner_config(learnerType, cfgRun);
    adversaryCfg = get_adversary_config(adversaryType, cfgRun);
    learner = init_learner(learnerCfg);
    adversary = init_adversary(adversaryCfg);

    actionHistory = zeros(T, 1);
    rewardHistory = zeros(T, 1);
    rateHistory = zeros(T, 1);

    jamHitHistory = zeros(T, 1);
    expectedJamHitHistory = zeros(T, 1);
    hitRiskAtActionHistory = zeros(T, 1);
    occHitHistory = zeros(T, 1);
    sinrHistory = zeros(T, 1);
    sinrDbHistory = zeros(T, 1);

    spectralEfficiencyHistory = zeros(T, 1);
    deliveredSpectralEfficiencyHistory = zeros(T, 1);
    pdrHistory = zeros(T, 1);
    goodputMbpsHistory = zeros(T, 1);
    adaptiveGoodputMbpsHistory = zeros(T, 1);
    cappedGoodputMbpsHistory = zeros(T, 1);
    fixedGoodputMbpsHistory = zeros(T, 1);
    berHistory = zeros(T, 1);
    retransmissionHistory = zeros(T, 1);
    switchingHistory = zeros(T, 1);

    overlapHistory = zeros(T, 1);
    riskAtActionHistory = zeros(T, 1);
    predictionHitHistory = zeros(T, 1);

    legacyEffectiveRewardHistory = zeros(T, 1);
    legacyEffectiveLossHistory = zeros(T, 1);
    predictedActionHistory = zeros(T, 1);
    selectedFcGHz = zeros(T, 1);

    piHistory = zeros(K, T);
    qHistory = zeros(K, T);
    attackInclusionHistory = zeros(K, T);
    jammedHistory = zeros(K, T);

    armRewardHistory = zeros(K, T);
    armRateHistory = zeros(K, T);
    armPdrHistory = zeros(K, T);
    armGoodputMbpsHistory = zeros(K, T);

    learnerGammaHistory = NaN(T, 1);
    learnerEtaHistory = NaN(T, 1);
    detectWindowMeanHistory = NaN(T, 1);
    explorationRiskHistory = NaN(T, 1);
    baseExplorationRiskHistory = NaN(T, 1);
    baseRiskHistory = NaN(T, 1);
    explorationHitRiskHistory = NaN(T, 1);
    baseExplorationHitRiskHistory = NaN(T, 1);
    baseHitRiskHistory = NaN(T, 1);
    masterLcMassHistory = NaN(T, 1);
    masterLocalMassHistory = NaN(T, 1);

    riskProjectionActiveHistory = false(T, 1);
    riskProjectionLambdaHistory = zeros(T, 1);
    riskProjectionKlHistory = zeros(T, 1);
    preProjectionHitRiskHistory = NaN(T, 1);
    postProjectionHitRiskHistory = NaN(T, 1);
    riskProjectionBudgetHistory = NaN(T, 1);
    riskProjectionViolationHistory = zeros(T, 1);

    for t = 1:T

        X_t = env.context(:, :, t);

        [q_t, advAux] = adversary_predict( ...
            adversary, X_t, actionHistory, t);

        [predictedAction_t, jammed_t, attackAux] = ...
            sample_attack_realization(adversary, q_t, t);

        attackInclusion_t = ...
            attackAux.inclusionProbability(:);

        if numel(attackInclusion_t) ~= K ...
                || any(~isfinite(attackInclusion_t)) ...
                || any(attackInclusion_t < 0) ...
                || any(attackInclusion_t > 1)
            error("Invalid attack inclusion probability.");
        end

        advAux.attackAction = attackAux.attackAction;
        advAux.attackSet = attackAux.attackSet;

        [a_t, pi_t, learnerAux, learner] = learner_select( ...
            learner, X_t, q_t, t, cfgRun);

        if isfield(learnerAux, "gamma")
            learnerGammaHistory(t) = learnerAux.gamma;
        end
        if isfield(learnerAux, "eta")
            learnerEtaHistory(t) = learnerAux.eta;
        end
        if isfield(learnerAux, "detectMean")
            detectWindowMeanHistory(t) = learnerAux.detectMean;
        end
        if isfield(learnerAux, "exploration")
            explorationRiskHistory(t) = ...
                learnerAux.exploration(:)' * q_t(:);
            explorationHitRiskHistory(t) = ...
                learnerAux.exploration(:)' * attackInclusion_t;
        end
        if isfield(learnerAux, "baseProb")
            baseRiskHistory(t) = ...
                learnerAux.baseProb(:)' * q_t(:);
            baseHitRiskHistory(t) = ...
                learnerAux.baseProb(:)' * attackInclusion_t;
        end
        if isfield(learnerAux, "baseExploration")
            baseExplorationRiskHistory(t) = ...
                learnerAux.baseExploration(:)' * q_t(:);
            baseExplorationHitRiskHistory(t) = ...
                learnerAux.baseExploration(:)' * attackInclusion_t;
        end
        if isfield(learnerAux, "masterProb") ...
                && numel(learnerAux.masterProb) >= 2
            masterLcMassHistory(t) = learnerAux.masterProb(1);
            masterLocalMassHistory(t) = learnerAux.masterProb(2);
        end

        if isfield(learnerAux, "riskProjectionActive")
            riskProjectionActiveHistory(t) = ...
                learnerAux.riskProjectionActive;
            riskProjectionLambdaHistory(t) = ...
                learnerAux.riskProjectionLambda;
            riskProjectionKlHistory(t) = ...
                learnerAux.riskProjectionKl;
            preProjectionHitRiskHistory(t) = ...
                learnerAux.preProjectionHitRisk;
            postProjectionHitRiskHistory(t) = ...
                learnerAux.postProjectionHitRisk;
            riskProjectionBudgetHistory(t) = ...
                learnerAux.riskProjectionBudget;
            riskProjectionViolationHistory(t) = ...
                learnerAux.riskProjectionViolation;
        end

        h_t = env.H(:, t);
        occ_t = env.occupied(:, t);
        noise_t = env.noisePower(:, t);

        outcomes = compute_all_arm_outcomes( ...
            h_t, occ_t, noise_t, jammed_t, cfgRun);

        armRewardHistory(:, t) = outcomes.reward;
        armRateHistory(:, t) = outcomes.rate;
        armPdrHistory(:, t) = outcomes.pdr;
        armGoodputMbpsHistory(:, t) = outcomes.goodputMbps;

        reward_t = outcomes.reward(a_t);
        rate_t = outcomes.rate(a_t);

        if t > 1
            switchingHistory(t) = ...
                double(a_t ~= actionHistory(t - 1));
        end

        overlap_t = pi_t' * q_t;
        riskAtAction_t = q_t(a_t);
        expectedJamHit_t = pi_t' * attackInclusion_t;
        hitRiskAtAction_t = attackInclusion_t(a_t);
        predictionHit_t = double(a_t == predictedAction_t);

        if isfield(learnerAux, "baseProb") ...
                && isfield(learnerAux, "exploration") ...
                && isfield(learnerAux, "gamma")

            reconstructedPolicy = ...
                (1 - learnerAux.gamma) ...
                .* learnerAux.baseProb(:) ...
                + learnerAux.gamma ...
                .* learnerAux.exploration(:);

            if isfield(learnerAux, "preProjectionPolicy")

                assert(norm( ...
                    reconstructedPolicy ...
                    - learnerAux.preProjectionPolicy(:), ...
                    Inf) < 1e-10, ...
                    "Pre-projection policy decomposition is inconsistent.");

                if learnerAux.riskProjectionActive ...
                        && learnerAux.riskProjectionFeasible

                    assert(expectedJamHit_t ...
                        <= learnerAux.riskProjectionBudget + 1e-8, ...
                        "Projected policy violated the hit-risk budget.");
                end

            else

                reconstructedOverlap = ...
                    reconstructedPolicy' * q_t(:);

                assert(abs( ...
                    reconstructedOverlap - overlap_t) < 1e-10, ...
                    "Overlap decomposition is inconsistent.");

                reconstructedExpectedHit = ...
                    reconstructedPolicy' * attackInclusion_t;

                assert(abs( ...
                    reconstructedExpectedHit ...
                    - expectedJamHit_t) < 1e-10, ...
                    "Expected jam-hit decomposition is inconsistent.");
            end
        end

        lambda = get_optional_scalar(cfgRun, "detect_lambda", 0.0);
        legacyEffectiveLoss_t = ...
            (1 - reward_t + lambda * riskAtAction_t) / (1 + lambda);
        legacyEffectiveReward_t = 1 - legacyEffectiveLoss_t;

        feedback.action = a_t;
        feedback.reward = reward_t;
        feedback.pi = pi_t;
        feedback.q = q_t;
        feedback.riskAtAction = riskAtAction_t;
        feedback.effectiveLoss = legacyEffectiveLoss_t;
        feedback.overlap = overlap_t;
        feedback.attackInclusionProbability = ...
            attackInclusion_t;
        feedback.expectedJamHit = expectedJamHit_t;
        feedback.hitRiskAtAction = hitRiskAtAction_t;

        learner = learner_update( ...
            learner, X_t, feedback, learnerAux, t, cfgRun);

        adversary = adversary_update( ...
            adversary, X_t, a_t, advAux, t);

        actionHistory(t) = a_t;
        rewardHistory(t) = reward_t;
        rateHistory(t) = rate_t;

        jamHitHistory(t) = outcomes.jammed(a_t);
        expectedJamHitHistory(t) = expectedJamHit_t;
        hitRiskAtActionHistory(t) = hitRiskAtAction_t;
        occHitHistory(t) = outcomes.occupied(a_t);
        sinrHistory(t) = outcomes.sinr(a_t);
        sinrDbHistory(t) = outcomes.sinrDb(a_t);

        spectralEfficiencyHistory(t) = ...
            outcomes.rawSpectralEfficiency(a_t);
        deliveredSpectralEfficiencyHistory(t) = ...
            outcomes.rate(a_t) / max(cfgRun.B, realmin);
        pdrHistory(t) = outcomes.pdr(a_t);
        goodputMbpsHistory(t) = outcomes.goodputMbps(a_t);
        adaptiveGoodputMbpsHistory(t) = ...
            outcomes.adaptiveGoodputMbps(a_t);
        cappedGoodputMbpsHistory(t) = ...
            outcomes.cappedGoodputMbps(a_t);
        fixedGoodputMbpsHistory(t) = ...
            outcomes.fixedGoodputMbps(a_t);
        berHistory(t) = outcomes.berBpsk(a_t);
        retransmissionHistory(t) = outcomes.retransmission(a_t);

        overlapHistory(t) = overlap_t;
        riskAtActionHistory(t) = riskAtAction_t;
        predictionHitHistory(t) = predictionHit_t;
        legacyEffectiveRewardHistory(t) = legacyEffectiveReward_t;
        legacyEffectiveLossHistory(t) = legacyEffectiveLoss_t;
        predictedActionHistory(t) = predictedAction_t;
        selectedFcGHz(t) = cfgRun.fc_GHz(a_t);

        piHistory(:, t) = pi_t;
        qHistory(:, t) = q_t;
        attackInclusionHistory(:, t) = attackInclusion_t;
        jammedHistory(:, t) = jammed_t;
    end

    results.learnerType = string(learnerType);
    results.learnerName = learner.name;
    results.adversaryType = string(adversaryType);
    results.environmentRegime = string(env.regime);
    results.rewardMode = string(cfgRun.reward_mode);

    results.action = actionHistory;
    results.reward = rewardHistory;
    results.rate = rateHistory;
    results.jamHit = jamHitHistory;
    results.expectedJamHit = expectedJamHitHistory;
    results.hitRiskAtAction = hitRiskAtActionHistory;
    results.occHit = occHitHistory;
    results.sinr = sinrHistory;
    results.sinrDb = sinrDbHistory;
    results.spectralEfficiency = spectralEfficiencyHistory;
    results.deliveredSpectralEfficiency = ...
        deliveredSpectralEfficiencyHistory;
    results.pdr = pdrHistory;
    results.goodputMbps = goodputMbpsHistory;
    results.adaptiveGoodputMbps = adaptiveGoodputMbpsHistory;
    results.cappedGoodputMbps = cappedGoodputMbpsHistory;
    results.fixedGoodputMbps = fixedGoodputMbpsHistory;
    results.ber = berHistory;
    results.retransmission = retransmissionHistory;
    results.switching = switchingHistory;

    results.armReward = armRewardHistory;
    results.armRate = armRateHistory;
    results.armPdr = armPdrHistory;
    results.armGoodputMbps = armGoodputMbpsHistory;

    results.overlap = overlapHistory;
    results.riskAtAction = riskAtActionHistory;
    results.predictionHit = predictionHitHistory;
    results.legacyEffectiveReward = legacyEffectiveRewardHistory;
    results.legacyEffectiveLoss = legacyEffectiveLossHistory;
    results.effectiveReward = legacyEffectiveRewardHistory;
    results.effectiveLoss = legacyEffectiveLossHistory;
    results.predictedAction = predictedActionHistory;
    results.selectedFcGHz = selectedFcGHz;
    results.pi = piHistory;
    results.q = qHistory;
    results.attackInclusionProbability = ...
        attackInclusionHistory;
    results.jammed = jammedHistory;
    results.finalLearner = learner;
    results.finalAdversary = adversary;
    results.learnerGamma = learnerGammaHistory;
    results.learnerEta = learnerEtaHistory;
    results.detectWindowMean = detectWindowMeanHistory;
    results.explorationRisk = explorationRiskHistory;
    results.baseExplorationRisk = baseExplorationRiskHistory;
    results.baseRisk = baseRiskHistory;
    results.explorationHitRisk = ...
        explorationHitRiskHistory;
    results.baseExplorationHitRisk = ...
        baseExplorationHitRiskHistory;
    results.baseHitRisk = baseHitRiskHistory;
    results.masterLcMass = masterLcMassHistory;
    results.masterLocalMass = masterLocalMassHistory;

    results.riskProjectionActive = ...
        riskProjectionActiveHistory;
    results.riskProjectionLambda = ...
        riskProjectionLambdaHistory;
    results.riskProjectionKl = ...
        riskProjectionKlHistory;
    results.preProjectionHitRisk = ...
        preProjectionHitRiskHistory;
    results.postProjectionHitRisk = ...
        postProjectionHitRiskHistory;
    results.riskProjectionBudget = ...
        riskProjectionBudgetHistory;
    results.riskProjectionViolation = ...
        riskProjectionViolationHistory;

    learnerTypeString = lower(string(learnerType));

    if ismember(learnerTypeString, ...
            ["bc_explore_only", "bc_detect", "bc_old_detect"])

        valid = isfinite(explorationRiskHistory) ...
            & isfinite(baseExplorationRiskHistory);

        assert(all(explorationRiskHistory(valid) ...
            <= baseExplorationRiskHistory(valid) + 1e-10), ...
            "Prediction tilt increased q-overlap exploration risk.");
    end

    if ismember(learnerTypeString, ...
            ["dpact_explore_only", "dpact_detect"])

        if isfield(learner, "predictionRiskMode") ...
                && learner.predictionRiskMode == "hit_probability"

            actualRisk = explorationHitRiskHistory;
            baseRisk = baseExplorationHitRiskHistory;
            message = ...
                "Prediction tilt increased expected jam-hit risk.";
        else
            actualRisk = explorationRiskHistory;
            baseRisk = baseExplorationRiskHistory;
            message = ...
                "Prediction tilt increased q-overlap exploration risk.";
        end

        valid = isfinite(actualRisk) & isfinite(baseRisk);
        assert(all(actualRisk(valid) <= baseRisk(valid) + 1e-10), ...
            message);
    end

end


function value = get_optional_scalar(inputStruct, fieldName, defaultValue)

    fieldName = char(fieldName);
    if isfield(inputStruct, fieldName)
        value = inputStruct.(fieldName);
    else
        value = defaultValue;
    end

    if ~isscalar(value) || ~isfinite(value)
        error("Configuration field '%s' must be finite.", fieldName);
    end

end
