function outputs = run_dynamic_pact_validation(mode)
%RUN_DYNAMIC_PACT_VALIDATION Validate the dynamic PACT backbone first.
%
% The suite checks three frozen requirements:
%   1. LC-only embedding reproduces LC-INF-Online.
%   2. The dynamic master stays competitive in the linear-friendly channel.
%   3. The local learner and master improve controlled nonlinear tasks.

    if nargin < 1
        mode = "smoke";
    end

    projectRoot = setup_paths();
    suite = get_dynamic_pact_validation_config(mode);

    outputRoot = fullfile(projectRoot, suite.outputRoot);
    tableFolder = fullfile(outputRoot, "tables");
    figureFolder = fullfile(outputRoot, "figures");
    rawFolder = fullfile(outputRoot, "raw");
    checkpointFolder = fullfile(outputRoot, "checkpoints");

    ensure_folder(tableFolder);
    ensure_folder(figureFolder);
    ensure_folder(rawFolder);
    ensure_folder(checkpointFolder);

    cfg = get_base_config();
    cfg.T = suite.T;
    cfg.seedList = suite.seedList;
    cfg.numSeeds = numel(suite.seedList);
    cfg.checkpoint_root = checkpointFolder;
    cfg.resume = true;
    cfg.use_parallel = true;
    cfg.store_full_histories = true;
    cfg.store_metric_timeseries = false;

    fprintf("\n########################################\n");
    fprintf("Dynamic PACT validation: %s\n", mode);
    fprintf("T = %d, seeds = %d\n", cfg.T, numel(cfg.seedList));
    fprintf("########################################\n");

    %% V1. Communication backbone
    variants = communication_variants();
    rows = cell(numel(variants) * numel(suite.adversaries), 1);
    raw = cell(numel(variants), numel(suite.adversaries));
    rowIndex = 0;

    for adversaryIndex = 1:numel(suite.adversaries)
        adversaryType = suite.adversaries(adversaryIndex);

        for variantIndex = 1:numel(variants)
            variant = variants(variantIndex);
            cfgRun = apply_variant(cfg, variant);

            multi = run_multi_seed_pair( ...
                cfgRun, variant.learnerType, adversaryType);

            rowIndex = rowIndex + 1;
            rows{rowIndex} = validation_summary_row( ...
                variant.name, adversaryType, multi);
            raw{variantIndex, adversaryIndex} = multi;
        end
    end

    tableV1 = vertcat(rows{:});
    write_table_bundle(tableV1, fullfile( ...
        tableFolder, "Table_V1_dynamic_communication"));

    save(fullfile(rawFolder, "V1_dynamic_communication.mat"), ...
        "raw", "tableV1", "cfg", "suite", "variants", "-v7.3");

    plot_dynamic_communication(tableV1, fullfile( ...
        figureFolder, "Figure_V1_dynamic_communication.png"));

    %% V2. Controlled nonlinear bandit tasks
    syntheticVariants = synthetic_variants();
    syntheticRows = cell( ...
        numel(syntheticVariants) ...
        * numel(suite.syntheticTasks) ...
        * suite.syntheticSeeds, 1);

    syntheticRaw = cell( ...
        numel(syntheticVariants), ...
        numel(suite.syntheticTasks), ...
        suite.syntheticSeeds);

    rowIndex = 0;

    for taskIndex = 1:numel(suite.syntheticTasks)
        task = suite.syntheticTasks(taskIndex);

        for variantIndex = 1:numel(syntheticVariants)
            variant = syntheticVariants(variantIndex);
            cfgRun = apply_variant(cfg, variant);

            for seedIndex = 1:suite.syntheticSeeds
                seed = 95000 + 100 * taskIndex + seedIndex;

                result = run_synthetic_dynamic_pair( ...
                    cfgRun, variant.learnerType, task, ...
                    seed, suite.syntheticT);

                rowIndex = rowIndex + 1;
                syntheticRows{rowIndex} = table( ...
                    task, variant.name, seed, ...
                    result.avgReward, result.oracleReward, ...
                    result.oracleCapture, result.avgOverlap, ...
                    'VariableNames', { ...
                        'Task', 'Variant', 'Seed', ...
                        'Reward', 'DynamicOracleReward', ...
                        'OracleCapture', 'Overlap'});

                syntheticRaw{variantIndex, taskIndex, seedIndex} = result;
            end
        end
    end

    rawTableV2 = vertcat(syntheticRows{:});
    tableV2 = aggregate_synthetic_table(rawTableV2);

    write_table_bundle(tableV2, fullfile( ...
        tableFolder, "Table_V2_dynamic_nonlinear"));

    save(fullfile(rawFolder, "V2_dynamic_nonlinear.mat"), ...
        "syntheticRaw", "rawTableV2", "tableV2", ...
        "cfg", "suite", "syntheticVariants", "-v7.3");

    plot_dynamic_nonlinear(tableV2, fullfile( ...
        figureFolder, "Figure_V2_dynamic_nonlinear.png"));

    %% Automatic acceptance report
    reportPath = fullfile(outputRoot, "VALIDATION_VERDICT.md");
    write_dynamic_validation_verdict(reportPath, tableV1, tableV2);

    outputs.outputRoot = outputRoot;
    outputs.tableV1 = tableV1;
    outputs.tableV2 = tableV2;
    outputs.reportPath = reportPath;

    fprintf("\nDynamic PACT validation completed.\n");
    fprintf("Read: %s\n", reportPath);

end


function variants = communication_variants()

    variants = repmat(struct( ...
        'name', "", 'learnerType', "", ...
        'forceBase', "none", 'gammaScale', NaN), 6, 1);

    variants(1) = make_variant( ...
        "LC-Tsallis-INF-Online", "lc_inf_online", "none", NaN);
    variants(2) = make_variant( ...
        "Static PACT-AFH-Base", "bc_nodetect", "none", NaN);
    variants(3) = make_variant( ...
        "D-PACT LC-only", "dpact_nodetect", "lc", 0.0);
    variants(4) = make_variant( ...
        "D-PACT Local-only", "dpact_nodetect", "local", 0.0);
    variants(5) = make_variant( ...
        "D-PACT-AFH-Base", "dpact_nodetect", "none", NaN);
    variants(6) = make_variant( ...
        "D-PACT-AFH", "dpact_detect", "none", NaN);

end


function variants = synthetic_variants()

    variants = repmat(struct( ...
        'name', "", 'learnerType', "", ...
        'forceBase', "none", 'gammaScale', NaN), 4, 1);

    variants(1) = make_variant( ...
        "LC-Tsallis-INF-Online", "lc_inf_online", "none", NaN);
    variants(2) = make_variant( ...
        "D-PACT LC-only", "dpact_nodetect", "lc", 0.0);
    variants(3) = make_variant( ...
        "D-PACT Local-only", "dpact_nodetect", "local", 0.0);
    variants(4) = make_variant( ...
        "D-PACT-AFH-Base", "dpact_nodetect", "none", NaN);

end


function variant = make_variant(name, learnerType, forceBase, gammaScale)

    variant.name = string(name);
    variant.learnerType = string(learnerType);
    variant.forceBase = string(forceBase);
    variant.gammaScale = gammaScale;

end


function cfgRun = apply_variant(cfg, variant)

    cfgRun = cfg;
    cfgRun.dynamic_force_base = variant.forceBase;

    if isfinite(variant.gammaScale)
        cfgRun.dynamic_master_gamma_scale = variant.gammaScale;
        cfgRun.dynamic_master_gamma_max = variant.gammaScale;
    end

end


function row = validation_summary_row(name, adversary, multi)

    s = multi.summary;

    row = table( ...
        string(name), string(adversary), ...
        s.meanAvgReward, s.ci95AvgReward, ...
        s.meanGoodputMbps, s.ci95GoodputMbps, ...
        s.meanPdr, s.ci95Pdr, ...
        s.meanOverlap, s.ci95Overlap, ...
        s.meanJamHitRate, s.ci95JamHitRate, ...
        s.meanMasterLcMass, s.meanMasterLocalMass, ...
        s.meanMasterEffectiveCount, s.meanRuntime, ...
        'VariableNames', { ...
            'Variant', 'Adversary', ...
            'Reward', 'RewardCI95', ...
            'GoodputMbps', 'GoodputCI95', ...
            'PDR', 'PDRCI95', ...
            'Overlap', 'OverlapCI95', ...
            'JamHit', 'JamHitCI95', ...
            'MasterLcMass', 'MasterLocalMass', ...
            'MasterEffectiveCount', 'RuntimeSeconds'});

end


function output = aggregate_synthetic_table(raw)

    tasks = unique(raw.Task, "stable");
    variants = unique(raw.Variant, "stable");
    rows = cell(numel(tasks) * numel(variants), 1);
    index = 0;

    for taskIndex = 1:numel(tasks)
        for variantIndex = 1:numel(variants)
            mask = raw.Task == tasks(taskIndex) ...
                & raw.Variant == variants(variantIndex);

            index = index + 1;
            [reward, rewardCI] = mean_ci(raw.Reward(mask));
            [capture, captureCI] = mean_ci(raw.OracleCapture(mask));

            rows{index} = table( ...
                tasks(taskIndex), variants(variantIndex), ...
                reward, rewardCI, ...
                mean(raw.DynamicOracleReward(mask)), ...
                capture, captureCI, ...
                'VariableNames', { ...
                    'Task', 'Variant', ...
                    'Reward', 'RewardCI95', ...
                    'DynamicOracleReward', ...
                    'OracleCapture', 'OracleCaptureCI95'});
        end
    end

    output = vertcat(rows{:});

end


function [meanValue, ci95] = mean_ci(values)

    values = values(isfinite(values));
    meanValue = mean(values);

    if numel(values) <= 1
        ci95 = NaN;
    else
        ci95 = 1.96 * std(values) / sqrt(numel(values));
    end

end


function ensure_folder(pathValue)

    if ~isfolder(pathValue)
        mkdir(pathValue);
    end

end
