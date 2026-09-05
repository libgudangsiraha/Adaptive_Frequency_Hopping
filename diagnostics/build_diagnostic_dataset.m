function dataset = build_diagnostic_dataset(cfg, seed, scenario)
%BUILD_DIAGNOSTIC_DATASET Generate a learner-independent reward dataset.
%
% scenario:
%   none  - no active jammer
%   sweep - deterministic exogenous sweep jammer
%
% The returned data use the same communication outcome function as the
% main experiment. Hence this diagnoses the actual context-to-reward map,
% rather than a separate toy communication model.

    scenario = lower(string(scenario));

    rng(seed);
    env = generate_environment(cfg);

    K = cfg.K;
    T = cfg.T;

    armReward = zeros(K, T);
    armGoodput = zeros(K, T);

    for t = 1:T

        jammed = false(K, 1);

        switch scenario
            case "none"
                % Leave jammed empty.

            case "sweep"
                width = max(1, min(K, round(cfg.M_jam)));
                firstChannel = mod(t - 1, K) + 1;
                indices = mod( ...
                    (firstChannel - 1) + (0:(width - 1)), ...
                    K) + 1;
                jammed(indices) = true;

            otherwise
                error("Unsupported diagnostic scenario: %s", scenario);
        end

        outcomes = compute_all_arm_outcomes( ...
            env.H(:, t), ...
            env.occupied(:, t), ...
            env.noisePower(:, t), ...
            jammed, ...
            cfg);

        armReward(:, t) = outcomes.reward;
        armGoodput(:, t) = outcomes.goodputMbps;
    end

    featureTensor = permute( ...
        env.context(2:4, :, :), [2, 3, 1]);

    features = reshape(featureTensor, K * T, 3);
    reward = armReward(:);
    goodput = armGoodput(:);

    roundIndex = repelem((1:T)', K);
    armIndex = repmat((1:K)', T, 1);

    dataset.seed = seed;
    dataset.scenario = scenario;
    dataset.env = env;
    dataset.features = features;
    dataset.reward = reward;
    dataset.goodput = goodput;
    dataset.roundIndex = roundIndex;
    dataset.armIndex = armIndex;
    dataset.armReward = armReward;
    dataset.armGoodput = armGoodput;

end
