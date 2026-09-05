function result = run_synthetic_dynamic_pair( ...
    cfg, learnerType, task, seed, T)
%RUN_SYNTHETIC_DYNAMIC_PAIR Bandit-only controlled contextual benchmark.

    rng(seed);

    cfgRun = cfg;
    cfgRun.T = T;
    cfgRun.store_full_histories = true;

    learnerCfg = get_learner_config(learnerType, cfgRun);
    learner = init_learner(learnerCfg);

    rewardHistory = zeros(T, 1);
    oracleHistory = zeros(T, 1);
    overlapHistory = zeros(T, 1);
    lcMassHistory = NaN(T, 1);
    localMassHistory = NaN(T, 1);

    q_t = ones(cfgRun.K, 1) / cfgRun.K;

    for t = 1:T
        raw = rand(3, cfgRun.K);
        X_t = [ones(1, cfgRun.K); raw];
        rewardVector = synthetic_reward(raw, task);

        [a_t, pi_t, aux, learner] = learner_select( ...
            learner, X_t, q_t, t, cfgRun);

        feedback.action = a_t;
        feedback.reward = rewardVector(a_t);
        feedback.pi = pi_t;
        feedback.q = q_t;
        feedback.riskAtAction = q_t(a_t);
        feedback.effectiveLoss = 1 - rewardVector(a_t);
        feedback.overlap = pi_t' * q_t;

        learner = learner_update( ...
            learner, X_t, feedback, aux, t, cfgRun);

        rewardHistory(t) = rewardVector(a_t);
        oracleHistory(t) = max(rewardVector);
        overlapHistory(t) = pi_t' * q_t;

        if isfield(aux, "masterProb")
            lcMassHistory(t) = aux.masterProb(1);
            localMassHistory(t) = aux.masterProb(2);
        end
    end

    result.task = string(task);
    result.learnerType = string(learnerType);
    result.seed = seed;
    result.avgReward = mean(rewardHistory);
    result.oracleReward = mean(oracleHistory);
    result.oracleCapture = sum(rewardHistory) / max(sum(oracleHistory), eps);
    result.avgOverlap = mean(overlapHistory);
    result.finalLearner = learner;
    result.reward = rewardHistory;
    result.oracle = oracleHistory;
    result.lcMass = lcMassHistory;
    result.localMass = localMassHistory;

end


function reward = synthetic_reward(features, task)

    x1 = features(1, :)';
    x2 = features(2, :)';
    x3 = features(3, :)';

    switch string(task)
        case "linear_monotone"
            reward = 0.50 .* x1 + 0.30 .* x2 + 0.20 .* x3;

        case "interaction"
            reward = 0.70 .* (x1 .* x3) + 0.30 .* x2;

        case "xor"
            reward = double(xor(x1 >= 0.5, x2 >= 0.5));
            reward = reward .* (0.5 + 0.5 .* x3);

        case "band_pass"
            reward = double(x1 >= 0.35 & x1 <= 0.70);
            reward = reward .* (0.4 + 0.6 .* x3);

        case "weight_flip"
            regime = x3 >= 0.5;
            reward = double(regime) .* x1 ...
                + double(~regime) .* (1 - x1);
            reward = reward .* (0.5 + 0.5 .* x2);

        otherwise
            error("Unknown synthetic task: %s", task);
    end

    reward = min(max(reward, 0), 1);

end
