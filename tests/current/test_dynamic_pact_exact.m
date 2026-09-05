clear; clc;

setup_paths();

cfg = get_base_config();
cfg.K = 4;
cfg.T = 20;
cfg.fc_GHz = linspace(12, 18, cfg.K);
cfg.fc = cfg.fc_GHz * 1e9;
cfg.dynamic_master_gamma_scale = 0.0;
cfg.dynamic_master_gamma_max = 0.0;
cfg.dynamic_force_base = "lc";

X_t = [ ...
    ones(1, cfg.K); ...
    0.9, 0.6, 0.3, 0.1; ...
    0.7, 0.5, 0.4, 0.2; ...
    1.0, 1.0, 0.0, 1.0];
q_t = [0.45; 0.30; 0.15; 0.10];

lcCfg = get_learner_config("lc_inf_online", cfg);
lc = init_learner(lcCfg);

[~, lcPi, ~, lc] = learner_select( ...
    lc, X_t, q_t, 1, cfg);

dynCfg = get_learner_config("dpact_nodetect", cfg);
dyn = init_learner(dynCfg);

[~, dynPi, dynAux, dyn] = learner_select( ...
    dyn, X_t, q_t, 1, cfg);

assert(max(abs(lcPi - dynPi)) < 1e-12, ...
    "LC-only dynamic embedding does not reproduce LC policy.");

assert(max(abs(dynAux.masterProb - [1; 0])) < 1e-12);
assert(abs(sum(dynPi) - 1) < 1e-12);

cfg.dynamic_force_base = "none";
cfg.dynamic_master_gamma_scale = 0.25;
cfg.dynamic_master_gamma_max = 0.10;

fullCfg = get_learner_config("dpact_detect", cfg);
full = init_learner(fullCfg);

[a_t, pi_t, aux, full] = learner_select( ...
    full, X_t, q_t, 1, cfg);

assert(isequal(size(aux.basePolicies), [cfg.K, 2]));
assert(abs(sum(pi_t) - 1) < 1e-12);
assert(all(pi_t > 0));

baseExplorationRisk = aux.baseExploration' * q_t;
explorationRisk = aux.exploration' * q_t;
assert(explorationRisk <= baseExplorationRisk + 1e-12, ...
    "Dynamic q-tilt increased exploration risk.");

feedback.action = a_t;
feedback.reward = 0.6;
feedback.pi = pi_t;
feedback.q = q_t;
feedback.riskAtAction = q_t(a_t);
feedback.effectiveLoss = 0.4;
feedback.overlap = pi_t' * q_t;

full = learner_update(full, X_t, feedback, aux, 1, cfg);

assert(full.numUpdates == 1);
assert(full.lcBase.numUpdates == 1);
assert(full.localBase.numUpdates == 1);
assert(all(isfinite(full.masterCumCommLoss)));
assert(all(isfinite(full.masterCumPredictionRisk)));

fprintf("Dynamic PACT exact test passed.\n");
