function multiResults = run_multi_seed_pair( ...
    cfg, learnerType, adversaryType)
%RUN_MULTI_SEED_PAIR Checkpointed, resumable, optionally parallel runner.
%
% Every completed seed is written immediately. A power loss therefore
% loses at most the currently running seed(s), never the whole experiment.

    if isfield(cfg, "seedList")
        seedList = cfg.seedList;
    else
        seedList = cfg.seed:(cfg.seed + cfg.numSeeds - 1);
    end

    numSeeds = numel(seedList);
    checkpointRoot = get_checkpoint_root(cfg);
    [experimentKey, signature] = build_experiment_key( ...
        cfg, learnerType, adversaryType);
    pairFolder = fullfile(checkpointRoot, experimentKey);

    if ~isfolder(pairFolder)
        mkdir(pairFolder);
    end

    fprintf("\n========================================\n");
    fprintf("Learner: %s\n", learnerType);
    fprintf("Adversary: %s\n", adversaryType);
    fprintf("Environment: %s\n", get_optional_string( ...
        cfg, "environment_regime", "stochastic"));
    fprintf("Number of seeds: %d\n", numSeeds);
    fprintf("Checkpoint: %s\n", pairFolder);
    fprintf("========================================\n");

    records = cell(numSeeds, 1);
    pending = false(numSeeds, 1);
    resume = get_optional_logical(cfg, "resume", true);
    resumedCount = 0;

    for seedIndex = 1:numSeeds
        seedFile = seed_checkpoint_file(pairFolder, seedList(seedIndex));

        if resume && isfile(seedFile)
            loaded = load(seedFile, "record", "signature");
            if isfield(loaded, "signature") ...
                    && strcmp(loaded.signature, signature)
                records{seedIndex} = loaded.record;
                resumedCount = resumedCount + 1;
                fprintf("[RESUME] Seed %d already completed.\n", ...
                    seedList(seedIndex));
                continue;
            end
        end

        pending(seedIndex) = true;
    end

    pendingIndex = find(pending);

    if ~isempty(pendingIndex)
        useParallel = prepare_parallel(cfg, numel(pendingIndex));

        if useParallel
            fprintf("Running %d pending seeds in parallel.\n", ...
                numel(pendingIndex));

            parfor pendingPosition = 1:numel(pendingIndex)
                seedIndex = pendingIndex(pendingPosition);
                seed = seedList(seedIndex);
                record = run_one_seed_record( ...
                    cfg, learnerType, adversaryType, seed);
                seedFile = seed_checkpoint_file(pairFolder, seed);
                save_seed_checkpoint(seedFile, record, signature);
            end
        else
            for pendingPosition = 1:numel(pendingIndex)
                seedIndex = pendingIndex(pendingPosition);
                seed = seedList(seedIndex);
                fprintf("Seed %d / %d: %d\n", ...
                    seedIndex, numSeeds, seed);
                record = run_one_seed_record( ...
                    cfg, learnerType, adversaryType, seed);
                seedFile = seed_checkpoint_file(pairFolder, seed);
                save_seed_checkpoint(seedFile, record, signature);
                fprintf([ ...
                    "  Reward %.4f | PDR %.4f | Goodput %.4f Mbps" ...
                    " | Time %.2f s\n"], ...
                    record.metrics.finalAvgReward, ...
                    record.metrics.finalPdr, ...
                    record.metrics.finalAvgGoodputMbps, ...
                    record.runtime);
            end
        end
    end

    for seedIndex = 1:numSeeds
        if isempty(records{seedIndex})
            seedFile = seed_checkpoint_file( ...
                pairFolder, seedList(seedIndex));
            loaded = load(seedFile, "record", "signature");
            if ~strcmp(loaded.signature, signature)
                error("Checkpoint signature mismatch: %s", seedFile);
            end
            records{seedIndex} = loaded.record;
        end
    end

    multiResults = aggregate_seed_records( ...
        records, cfg, learnerType, adversaryType);

    % Expose checkpoint diagnostics so tests and callers can verify that
    % an interrupted experiment really resumed instead of rerunning.
    multiResults.checkpointFolder = string(pairFolder);
    multiResults.numResumedSeeds = resumedCount;
    multiResults.numExecutedSeeds = numel(pendingIndex);

    pairSummaryFile = fullfile(pairFolder, "pair_summary.mat");
    save(pairSummaryFile, "multiResults", "signature", "-v7.3");

end


function filePath = seed_checkpoint_file(folder, seed)

    filePath = fullfile(folder, sprintf('seed_%d.mat', seed));

end


function root = get_checkpoint_root(cfg)

    if isfield(cfg, "checkpoint_root") ...
            && strlength(string(cfg.checkpoint_root)) > 0
        root = char(cfg.checkpoint_root);
    else
        projectRoot = setup_paths();
        root = fullfile(projectRoot, "results", "checkpoints");
    end

    if ~isfolder(root)
        mkdir(root);
    end

end


function useParallel = prepare_parallel(cfg, numPending)

    useParallel = get_optional_logical(cfg, "use_parallel", true) ...
        && numPending >= 2 ...
        && license('test', 'Distrib_Computing_Toolbox');

    if ~useParallel
        return;
    end

    try
        pool = gcp('nocreate');
        if isempty(pool)
            workers = get_optional_scalar(cfg, "parallel_workers", 0);
            if workers > 0
                parpool('local', round(workers));
            else
                parpool('local');
            end
        end
    catch warningInfo
        warning("Parallel pool unavailable; using serial: %s", ...
            warningInfo.message);
        useParallel = false;
    end

end


function value = get_optional_logical(inputStruct, fieldName, defaultValue)

    fieldName = char(fieldName);
    if isfield(inputStruct, fieldName)
        value = logical(inputStruct.(fieldName));
    else
        value = logical(defaultValue);
    end

end


function value = get_optional_scalar(inputStruct, fieldName, defaultValue)

    fieldName = char(fieldName);
    if isfield(inputStruct, fieldName)
        value = inputStruct.(fieldName);
    else
        value = defaultValue;
    end

end


function value = get_optional_string(inputStruct, fieldName, defaultValue)

    fieldName = char(fieldName);
    if isfield(inputStruct, fieldName)
        value = string(inputStruct.(fieldName));
    else
        value = string(defaultValue);
    end

end
