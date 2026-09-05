clear; clc; close all;

setup_paths();

run('tests/current/test_dynamic_pact_exact.m');

cfg = get_base_config();
cfg.T = 120;
cfg.seedList = 97001:97002;
cfg.numSeeds = numel(cfg.seedList);
cfg.K = 6;
cfg.fc_GHz = linspace(12, 18, cfg.K);
cfg.fc = cfg.fc_GHz * 1e9;
cfg.use_parallel = false;
cfg.resume = false;
cfg.store_full_histories = true;
cfg.store_metric_timeseries = false;
cfg.checkpoint_root = fullfile( ...
    tempdir, 'pact_dynamic_smoke_checkpoints');

if isfolder(cfg.checkpoint_root)
    rmdir(cfg.checkpoint_root, 's');
end

base = run_multi_seed_pair( ...
    cfg, "dpact_nodetect", "none");
full = run_multi_seed_pair( ...
    cfg, "dpact_detect", "contextual_expert");

assert(all(isfinite(base.avgReward)));
assert(all(isfinite(full.avgReward)));
assert(all(isfinite(base.masterLcMass)));
assert(all(isfinite(full.masterLocalMass)));
assert(all(base.masterLcMass >= 0 & base.masterLcMass <= 1));
assert(all(full.masterLocalMass >= 0 & full.masterLocalMass <= 1));

outputs = run_dynamic_pact_validation("smoke");
assert(istable(outputs.tableV1));
assert(istable(outputs.tableV2));
assert(isfile(outputs.reportPath));

fprintf("Dynamic PACT smoke test passed.\n");
