clear; clc;
projectRoot = setup_paths();

cfg = get_base_config();
cfg.K = 4;
cfg.T = 30;
cfg.fc_GHz = linspace(12, 18, cfg.K);
cfg.fc = cfg.fc_GHz * 1e9;
cfg.seedList = 78001:78002;
cfg.numSeeds = 2;
cfg.use_parallel = false;
cfg.store_full_histories = false;
cfg.store_metric_timeseries = false;
cfg.checkpoint_root = fullfile( ...
    projectRoot, "results", "test_checkpoints_v2");

if isfolder(cfg.checkpoint_root)
    rmdir(cfg.checkpoint_root, 's');
end

%% First run: both seeds must execute and be written immediately.
first = run_multi_seed_pair( ...
    cfg, "bc_detect", "contextual_expert");

pairFolder = char(first.checkpointFolder);
filesBefore = dir(fullfile(pairFolder, "seed_*.mat"));

assert(isfolder(pairFolder), ...
    "Checkpoint pair folder was not created.");
assert(numel(filesBefore) == numel(cfg.seedList), ...
    "Expected %d seed checkpoints, found %d in %s.", ...
    numel(cfg.seedList), numel(filesBefore), pairFolder);
assert(first.numExecutedSeeds == numel(cfg.seedList));
assert(first.numResumedSeeds == 0);

%% Second run: no seed may execute again.
second = run_multi_seed_pair( ...
    cfg, "bc_detect", "contextual_expert");

filesAfter = dir(fullfile(pairFolder, "seed_*.mat"));

assert(numel(filesAfter) == numel(cfg.seedList), ...
    "Checkpoint count changed after resume.");
assert(second.numExecutedSeeds == 0, ...
    "Resume test reran one or more completed seeds.");
assert(second.numResumedSeeds == numel(cfg.seedList), ...
    "Resume test did not load all completed seeds.");
assert(max(abs(first.avgReward - second.avgReward)) < 1e-12, ...
    "Resumed results differ from the original results.");

rmdir(cfg.checkpoint_root, 's');
disp("PACT-AFH v2 checkpoint/resume test passed.");
