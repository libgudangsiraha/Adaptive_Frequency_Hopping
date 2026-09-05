function oracle = evaluate_pact_expert_oracle( ...
    env, armReward, cfg, mode, roundRange)
%EVALUATE_PACT_EXPERT_ORACLE Fixed and dynamic PACT expert oracles.

    if nargin < 5 || isempty(roundRange)
        roundRange = 1:size(armReward, 2);
    end

    cfgMode = cfg;
    cfgMode.pact_expert_bank_mode = string(mode);

    expertCfg = get_pact_expert_config(cfgMode);
    bank = build_pact_experts(expertCfg);

    numExperts = bank.numExperts;
    numRounds = numel(roundRange);

    rewardByExpert = zeros(numExperts, numRounds);
    dynamicArmReward = zeros(numRounds, 1);

    for localIndex = 1:numRounds

        t = roundRange(localIndex);
        advice = evaluate_pact_experts( ...
            env.context(:, :, t), bank);

        rewardVector = armReward(:, t);
        rewardByExpert(:, localIndex) = advice' * rewardVector;
        dynamicArmReward(localIndex) = max(rewardVector);
    end

    cumulativeExpertReward = sum(rewardByExpert, 2);
    [bestFixedTotal, bestIndex] = max(cumulativeExpertReward);

    dynamicExpertTotal = sum(max(rewardByExpert, [], 1));
    dynamicArmTotal = sum(dynamicArmReward);

    oracle.mode = string(mode);
    oracle.numExperts = numExperts;
    oracle.bestFixedTotal = bestFixedTotal;
    oracle.bestFixedMean = bestFixedTotal / numRounds;
    oracle.bestFixedIndex = bestIndex;
    oracle.bestFixedName = bank.names(bestIndex);
    oracle.dynamicExpertTotal = dynamicExpertTotal;
    oracle.dynamicExpertMean = dynamicExpertTotal / numRounds;
    oracle.dynamicArmTotal = dynamicArmTotal;
    oracle.dynamicArmMean = dynamicArmTotal / numRounds;

    oracle.fixedCapture = safe_ratio( ...
        bestFixedTotal, dynamicArmTotal);

    oracle.dynamicExpertCapture = safe_ratio( ...
        dynamicExpertTotal, dynamicArmTotal);

end


function value = safe_ratio(numerator, denominator)

    if denominator <= eps
        value = NaN;
    else
        value = numerator / denominator;
    end

end
