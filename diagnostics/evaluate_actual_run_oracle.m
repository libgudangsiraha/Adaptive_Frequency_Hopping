function summary = evaluate_actual_run_oracle( ...
    multiResults, cfg, expertMode)
%EVALUATE_ACTUAL_RUN_ORACLE Decompose representation and aggregation gaps.
%
% For each stored seed, the environment is regenerated exactly from that
% seed. The full-arm rewards are taken from the actual closed-loop run.

    numSeeds = numel(multiResults.seedList);

    actualMean = NaN(numSeeds, 1);
    fixedMean = NaN(numSeeds, 1);
    dynamicExpertMean = NaN(numSeeds, 1);
    dynamicArmMean = NaN(numSeeds, 1);

    for seedIndex = 1:numSeeds

        seed = multiResults.seedList(seedIndex);
        results = multiResults.allResults{seedIndex};

        if ~isfield(results, "armReward")
            error([ ...
                "Actual-run oracle requires full histories. " ...
                "Set store_full_histories=true."]);
        end

        rng(seed);
        env = generate_environment(cfg);

        oracle = evaluate_pact_expert_oracle( ...
            env, results.armReward, cfg, expertMode, []);

        actualMean(seedIndex) = mean(results.reward);
        fixedMean(seedIndex) = oracle.bestFixedMean;
        dynamicExpertMean(seedIndex) = oracle.dynamicExpertMean;
        dynamicArmMean(seedIndex) = oracle.dynamicArmMean;
    end

    summary.actualMean = mean(actualMean, "omitnan");
    summary.bestFixedMean = mean(fixedMean, "omitnan");
    summary.dynamicExpertMean = mean(dynamicExpertMean, "omitnan");
    summary.dynamicArmMean = mean(dynamicArmMean, "omitnan");

    % Positive means the fixed expert class can do better than the online
    % learner; negative means the adaptive learner beat every fixed expert.
    summary.aggregationGap = ...
        summary.bestFixedMean - summary.actualMean;

    summary.representationGap = ...
        summary.dynamicArmMean - summary.bestFixedMean;

    summary.actualValues = actualMean;
    summary.fixedValues = fixedMean;
    summary.dynamicExpertValues = dynamicExpertMean;
    summary.dynamicArmValues = dynamicArmMean;

end
