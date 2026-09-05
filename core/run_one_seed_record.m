function record = run_one_seed_record( ...
    cfg, learnerType, adversaryType, seed)
%RUN_ONE_SEED_RECORD Execute and summarize one independently seeded run.

    learnerTypeString = lower(string(learnerType));
    cfgRun = cfg;

    rng(seed);
    env = generate_environment(cfgRun);

    if ismember(learnerTypeString, ["lc_inf", "lc_inf_pool"])
        temporaryConfig = get_learner_config(learnerType, cfgRun);
        poolConfig = cfgRun;
        poolConfig.T = temporaryConfig.context_pool_size;
        rng(seed + 50000);
        poolEnvironment = generate_environment(poolConfig);
        cfgRun.contextPool = poolEnvironment.context;
    end

    rng(seed + 100000);
    timer = tic;
    results = run_single_pair( ...
        cfgRun, env, learnerType, adversaryType);
    runtime = toc(timer);
    metrics = compute_pair_metrics(results, cfgRun);

    if get_optional_logical(cfgRun, "store_full_histories", true)
        storedResults = results;
    else
        storedResults = compact_result(results);
    end

    if get_optional_logical(cfgRun, "store_metric_timeseries", true)
        storedMetrics = metrics;
    else
        storedMetrics = compact_metrics(metrics);
    end

    diagnostics = struct();
    diagnostics.avgBaseRisk = mean(results.baseRisk, "omitnan");
    diagnostics.avgExplorationRisk = ...
        mean(results.explorationRisk, "omitnan");
    diagnostics.avgBaseExplorationRisk = ...
        mean(results.baseExplorationRisk, "omitnan");
    diagnostics.sigmaRcond = NaN;
    diagnostics.maxThetaHatNorm = NaN;
    diagnostics.effectiveExpertCount = NaN;
    diagnostics.uniformExpertMass = NaN;
    diagnostics.coarseScaleMass = NaN;
    diagnostics.mediumScaleMass = NaN;
    diagnostics.fineScaleMass = NaN;
    diagnostics.linearFamilyMass = NaN;
    diagnostics.partitionFamilyMass = NaN;
    diagnostics.predictorRegret = NaN;
    diagnostics.predictorGain = NaN;
    diagnostics.folpettiSuccessRate = NaN;
    diagnostics.masterLcMass = NaN;
    diagnostics.masterLocalMass = NaN;
    diagnostics.masterEffectiveCount = NaN;
    diagnostics.maxLcOffPolicyRatio = NaN;
    diagnostics.maxLocalOffPolicyRatio = NaN;

    finalLearner = results.finalLearner;

    if ismember(learnerTypeString, ...
            ["lc_inf", "lc_inf_pool", "lc_inf_online"])
        diagnostics.sigmaRcond = finalLearner.sigmaRcond;
        diagnostics.maxThetaHatNorm = finalLearner.maxThetaHatNorm;
    end

    if ismember(learnerTypeString, bc_types())
        finalExpertProb = compute_final_bc_expert_prob( ...
            finalLearner, cfgRun.T + 1);
        positive = finalExpertProb(finalExpertProb > 0);
        diagnostics.effectiveExpertCount = exp( ...
            -sum(positive .* log(positive)));
        diagnostics.uniformExpertMass = sum( ...
            finalExpertProb(finalLearner.expertBank.isUniform));

        diagnostics.coarseScaleMass = family_scale_mass( ...
            finalExpertProb, finalLearner.expertBank, 1);
        diagnostics.mediumScaleMass = family_scale_mass( ...
            finalExpertProb, finalLearner.expertBank, 2);
        diagnostics.fineScaleMass = family_scale_mass( ...
            finalExpertProb, finalLearner.expertBank, 3);

        if isfield(finalLearner.expertBank, "familyIndex")
            diagnostics.partitionFamilyMass = sum( ...
                finalExpertProb( ...
                    finalLearner.expertBank.familyIndex == 1));
            diagnostics.linearFamilyMass = sum( ...
                finalExpertProb( ...
                    finalLearner.expertBank.familyIndex == 2));
        end
    end

    isDynamicLearner = ...
        isfield(finalLearner, "lastMasterProb") ...
        && isfield(finalLearner, "lcBase") ...
        && isfield(finalLearner, "localBase");

    if isDynamicLearner
        probability = finalLearner.lastMasterProb(:);
        positive = probability(probability > 0);
        diagnostics.masterEffectiveCount = exp( ...
            -sum(positive .* log(positive)));
        diagnostics.masterLcMass = ...
            mean(results.masterLcMass, "omitnan");
        diagnostics.masterLocalMass = ...
            mean(results.masterLocalMass, "omitnan");
        diagnostics.sigmaRcond = finalLearner.lcBase.sigmaRcond;
        diagnostics.maxThetaHatNorm = ...
            finalLearner.lcBase.maxThetaHatNorm;
        diagnostics.maxLcOffPolicyRatio = ...
            finalLearner.lcBase.maxOffPolicyRatio;
        diagnostics.maxLocalOffPolicyRatio = ...
            finalLearner.localBase.maxOffPolicyRatio;
    end

    finalAdversary = results.finalAdversary;
    if isfield(finalAdversary, "predictorRegret")
        diagnostics.predictorRegret = finalAdversary.predictorRegret;
    end
    if isfield(finalAdversary, "cumulativeMixtureGain")
        diagnostics.predictorGain = ...
            finalAdversary.cumulativeMixtureGain / cfgRun.T;
    end
    if string(adversaryType) == "folpetti_ts" ...
            && isfield(finalAdversary, "cumulativeAttackSuccess")
        diagnostics.folpettiSuccessRate = ...
            finalAdversary.cumulativeAttackSuccess ...
            / max(finalAdversary.numUpdates, 1);
    end

    record.seed = seed;
    record.runtime = runtime;
    record.results = storedResults;
    record.metrics = storedMetrics;
    record.diagnostics = diagnostics;
    record.completedAt = string(datetime('now'));

end


function mass = family_scale_mass(probability, bank, scaleIndex)

    mask = bank.scaleIndex == scaleIndex;
    mass = sum(probability(mask));

end


function probability = compute_final_bc_expert_prob(learner, nextTime)

    etaNext = learner.etaScale / sqrt(max(nextTime, 1));
    mode = string(learner.predictionLossMode);

    switch mode
        case "dual_current"
            effectiveLoss = learner.cumCommExpertLoss ...
                + learner.detectBeta .* learner.cumPredictionExpertRisk;
        case {"legacy_normalized", "scale_control"}
            effectiveLoss = learner.cumLegacyExpertLoss;
        otherwise
            effectiveLoss = learner.cumCommExpertLoss;
    end

    probability = tsallis_ftrl_policy(effectiveLoss, etaNext);

end


function types = bc_types()

    types = ["bc_nodetect", "bc_loss_only", "bc_explore_only", ...
        "bc_detect", "bc_old_loss_only", "bc_old_detect", ...
        "bc_scale_control"];

end


function compact = compact_result(results)
% Compact seed checkpoint for modules that do not need raw trajectories.

    keepFields = [ ...
        "learnerType", "learnerName", "adversaryType", ...
        "environmentRegime", "rewardMode"];

    compact = struct();
    for index = 1:numel(keepFields)
        fieldName = char(keepFields(index));
        if isfield(results, fieldName)
            compact.(fieldName) = results.(fieldName);
        end
    end

end

function compact = compact_metrics(metrics)

    compact = struct();
    names = fieldnames(metrics);

    for index = 1:numel(names)
        name = names{index};
        value = metrics.(name);
        keep = startsWith(name, "final") ...
            || startsWith(name, "normalized") ...
            || isscalar(value) ...
            || isstring(value) ...
            || ischar(value);
        if keep
            compact.(name) = value;
        end
    end

end


function types = dynamic_types()

    types = [ ...
        "dpact_nodetect", ...
        "dpact_loss_only", ...
        "dpact_explore_only", ...
        "dpact_detect", ...
        "dpact_safe"];

end


function value = get_optional_logical(inputStruct, fieldName, defaultValue)

    fieldName = char(fieldName);
    if isfield(inputStruct, fieldName)
        value = logical(inputStruct.(fieldName));
    else
        value = logical(defaultValue);
    end

end
