function tableD4 = run_synthetic_expressivity_diagnostic( ...
    cfg, diagCfg)
%RUN_SYNTHETIC_EXPRESSIVITY_DIAGNOSTIC Audit current expert expressivity.
%
% The current partition experts quantize features but still use one global,
% nonnegative additive score. This benchmark checks what that class can and
% cannot represent.

    tasks = diagCfg.syntheticTasks;
    modes = ["partition", "linear", "hybrid"];

    rows = cell( ...
        numel(tasks) * numel(modes) ...
        * diagCfg.syntheticSeeds, 1);

    rowIndex = 0;

    for seedOffset = 1:diagCfg.syntheticSeeds

        seed = 88000 + seedOffset;
        rng(seed);

        K = cfg.K;
        T = diagCfg.syntheticT;

        features = rand(3, K, T);
        context = zeros(4, K, T);
        context(1, :, :) = 1;
        context(2:4, :, :) = features;

        env.context = context;

        for taskIndex = 1:numel(tasks)

            task = tasks(taskIndex);
            reward = synthetic_reward(features, task);

            for modeIndex = 1:numel(modes)

                mode = modes(modeIndex);

                oracle = evaluate_pact_expert_oracle( ...
                    env, reward, cfg, mode, []);

                rowIndex = rowIndex + 1;

                rows{rowIndex} = table( ...
                    seed, ...
                    task, ...
                    mode, ...
                    oracle.numExperts, ...
                    oracle.bestFixedMean, ...
                    oracle.dynamicExpertMean, ...
                    oracle.dynamicArmMean, ...
                    oracle.fixedCapture, ...
                    oracle.dynamicExpertCapture, ...
                    'VariableNames', { ...
                        'Seed', ...
                        'Task', ...
                        'ExpertMode', ...
                        'NumExperts', ...
                        'BestFixedReward', ...
                        'DynamicExpertReward', ...
                        'DynamicArmReward', ...
                        'FixedOracleCapture', ...
                        'DynamicExpertCapture'});
            end
        end
    end

    raw = vertcat(rows{:});
    tableD4 = aggregate_synthetic(raw);

end


function reward = synthetic_reward(features, task)

    x1 = squeeze(features(1, :, :));
    x2 = squeeze(features(2, :, :));
    x3 = squeeze(features(3, :, :));

    switch task
        case "linear_monotone"
            reward = 0.50 * x1 + 0.30 * x2 + 0.20 * x3;

        case "interaction"
            reward = 0.70 * (x1 .* x3) + 0.30 * x2;

        case "xor"
            reward = double(xor(x1 >= 0.5, x2 >= 0.5));
            reward = reward .* (0.5 + 0.5 * x3);

        case "band_pass"
            reward = double(x1 >= 0.35 & x1 <= 0.70);
            reward = reward .* (0.4 + 0.6 * x3);

        case "weight_flip"
            regime = x3 >= 0.5;
            reward = regime .* x1 + (~regime) .* (1 - x1);
            reward = reward .* (0.5 + 0.5 * x2);

        otherwise
            error("Unknown synthetic task: %s", task);
    end

    reward = min(max(reward, 0), 1);

end


function output = aggregate_synthetic(raw)

    tasks = unique(raw.Task, "stable");
    modes = unique(raw.ExpertMode, "stable");

    rows = cell(numel(tasks) * numel(modes), 1);
    index = 0;

    for taskIndex = 1:numel(tasks)
        for modeIndex = 1:numel(modes)

            mask = ...
                raw.Task == tasks(taskIndex) ...
                & raw.ExpertMode == modes(modeIndex);

            index = index + 1;

            rows{index} = table( ...
                tasks(taskIndex), ...
                modes(modeIndex), ...
                mean(raw.NumExperts(mask)), ...
                mean(raw.BestFixedReward(mask)), ...
                mean(raw.DynamicExpertReward(mask)), ...
                mean(raw.DynamicArmReward(mask)), ...
                mean(raw.FixedOracleCapture(mask)), ...
                mean(raw.DynamicExpertCapture(mask)), ...
                'VariableNames', { ...
                    'Task', ...
                    'ExpertMode', ...
                    'NumExperts', ...
                    'BestFixedReward', ...
                    'DynamicExpertReward', ...
                    'DynamicArmReward', ...
                    'FixedOracleCapture', ...
                    'DynamicExpertCapture'});
        end
    end

    output = vertcat(rows{:});

end
