function outputs = run_final_c4(mode)
%RUN_FINAL_C4 Final D-PACT mechanism ablation.
%
% The ablation isolates:
%   global LC base;
%   local base;
%   dynamic communication-only master;
%   calibrated hit-risk master;
%   final Safe95 projection.

    if nargin < 1
        mode = "quick";
    end

    projectRoot = setup_paths();
    suite = get_final_c1_c4_config(mode);
    safePoint = resolve_final_safe_point( ...
        projectRoot, suite);

    outputRoot = fullfile( ...
        projectRoot, "results", "final_c4", char(mode));

    tableFolder = fullfile(outputRoot, "tables");
    figureFolder = fullfile(outputRoot, "figures");
    rawFolder = fullfile(outputRoot, "raw");
    checkpointFolder = fullfile(outputRoot, "checkpoints");

    ensure_folder(tableFolder);
    ensure_folder(figureFolder);
    ensure_folder(rawFolder);
    ensure_folder(checkpointFolder);

    cfgBase = get_base_config();
    cfgBase.T = suite.T;
    cfgBase.seedList = suite.c4Seeds;
    cfgBase.numSeeds = numel(cfgBase.seedList);
    cfgBase.M_jam = suite.attackBudget;
    cfgBase.sweep_width = suite.attackBudget;
    cfgBase.folpetti_mc_samples = suite.folpettiMcSamples;
    cfgBase.environment_regime = "stochastic";
    cfgBase.dynamic_prediction_risk_mode = "hit_probability";
    cfgBase.detect_beta = suite.beta;
    cfgBase.explore_nu = suite.nu;
    cfgBase.dynamic_safe_tau = safePoint.tau;
    cfgBase.resume = true;
    cfgBase.use_parallel = true;
    cfgBase.parallel_workers = 0;
    cfgBase.checkpoint_root = checkpointFolder;
    cfgBase.store_full_histories = false;
    cfgBase.store_metric_timeseries = false;

    rows = cell(numel(suite.c4Labels), 1);
    raw = cell(numel(suite.c4Labels), 1);

    for index = 1:numel(suite.c4Labels)

        cfg = cfgBase;
        cfg.dynamic_force_base = ...
            suite.c4ForceBase(index);

        learner = suite.c4Learners(index);
        label = suite.c4Labels(index);

        fprintf("\n===== FINAL C4 | %s =====\n", label);

        result = run_multi_seed_pair( ...
            cfg, learner, suite.mainAdversary);

        raw{index} = result;

        extra.Variant = label;
        extra.ForceBase = cfg.dynamic_force_base;
        extra.Tau = NaN;
        extra.MasterLcMass = result.summary.meanMasterLcMass;
        extra.MasterLcMassCI95 = result.summary.ci95MasterLcMass;
        extra.MasterLocalMass = result.summary.meanMasterLocalMass;
        extra.MasterLocalMassCI95 = ...
            result.summary.ci95MasterLocalMass;
        extra.MasterEffectiveCount = ...
            result.summary.meanMasterEffectiveCount;
        extra.MasterEffectiveCountCI95 = ...
            result.summary.ci95MasterEffectiveCount;

        if learner == "dpact_safe"
            extra.Tau = safePoint.tau;
        end

        rows{index} = build_communication_summary_row( ...
            result, extra);

        rows{index}.Learner = label;

        partial = vertcat(rows{1:index});
        writetable(partial, fullfile( ...
            tableFolder, "Table_C4_partial.csv"));

        save(fullfile(rawFolder, "C4_partial.mat"), ...
            "rows", "raw", "cfgBase", ...
            "suite", "safePoint", "-v7.3");
    end

    tableC4 = vertcat(rows{:});

    write_table_bundle(tableC4, fullfile( ...
        tableFolder, "Table_C4_ablation"));

    save(fullfile(rawFolder, "C4_final.mat"), ...
        "tableC4", "raw", "cfgBase", ...
        "suite", "safePoint", "-v7.3");

    plot_final_c4_ablation( ...
        tableC4, fullfile( ...
            figureFolder, ...
            "Figure_C4_mechanism_ablation.png"));

    outputs.outputRoot = outputRoot;
    outputs.tableC4 = tableC4;
    outputs.safePoint = safePoint;

end


function safePoint = resolve_final_safe_point( ...
    projectRoot, suite)

    try
        safePoint = resolve_dynamic_safe_operating_point( ...
            projectRoot, suite.safeLabel);
    catch
        safePoint.label = suite.safeLabel;
        safePoint.tau = suite.safeFallbackTau;
        safePoint.sourcePath = "explicit fallback";
        warning( ...
            "Safe scan unavailable; using explicit tau=%.4f.", ...
            safePoint.tau);
    end

end


function ensure_folder(pathValue)

    if ~isfolder(pathValue)
        mkdir(pathValue);
    end

end
