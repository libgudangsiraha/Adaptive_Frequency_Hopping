function outputs = run_final_c2(mode)
%RUN_FINAL_C2 Final main-performance experiment.
%
% C2 uses the white-box contextual attacker and records full running
% curves. All final baselines, D-PACT-Base, D-PACT-Hit, and Safe95 use
% common seeds and the frozen beta=16, nu=0 operating point.

    if nargin < 1
        mode = "quick";
    end

    projectRoot = setup_paths();
    suite = get_final_c1_c4_config(mode);
    safePoint = resolve_final_safe_point( ...
        projectRoot, suite);

    outputRoot = fullfile( ...
        projectRoot, "results", "final_c2", char(mode));

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
    cfg.seedList = suite.c2Seeds;
    cfg.numSeeds = numel(cfg.seedList);
    cfg.M_jam = suite.attackBudget;
    cfg.sweep_width = suite.attackBudget;
    cfg.folpetti_mc_samples = suite.folpettiMcSamples;
    cfg.environment_regime = "stochastic";
    cfg.dynamic_prediction_risk_mode = "hit_probability";
    cfg.detect_beta = suite.beta;
    cfg.explore_nu = suite.nu;
    cfg.dynamic_safe_tau = safePoint.tau;
    cfg.resume = true;
    cfg.use_parallel = true;
    cfg.parallel_workers = 0;
    cfg.checkpoint_root = checkpointFolder;
    cfg.store_full_histories = false;
    cfg.store_metric_timeseries = true;

    rows = cell(numel(suite.c2Learners), 1);
    raw = repmat(struct( ...
        'name', "", ...
        'learnerType', "", ...
        'multiResults', []), ...
        numel(suite.c2Learners), 1);

    for index = 1:numel(suite.c2Learners)

        learner = suite.c2Learners(index);

        fprintf("\n===== FINAL C2 | %s =====\n", ...
            get_learner_display_name(learner));

        result = run_multi_seed_pair( ...
            cfg, learner, suite.mainAdversary);

        raw(index).name = final_display_name(learner);
        raw(index).learnerType = learner;
        raw(index).multiResults = result;

        extra.Tau = NaN;

        if learner == "dpact_safe"
            extra.Tau = safePoint.tau;
        end

        rows{index} = build_communication_summary_row( ...
            result, extra);

        rows{index}.Learner = final_display_name(learner);

        partial = vertcat(rows{1:index});
        writetable(partial, fullfile( ...
            tableFolder, "Table_C2_partial.csv"));

        save(fullfile(rawFolder, "C2_partial.mat"), ...
            "raw", "rows", "cfg", "suite", ...
            "safePoint", "-v7.3");
    end

    tableC2 = vertcat(rows{:});

    write_table_bundle(tableC2, fullfile( ...
        tableFolder, "Table_C2_main_performance"));

    save(fullfile(rawFolder, "C2_final.mat"), ...
        "tableC2", "raw", "cfg", ...
        "suite", "safePoint", "-v7.3");

    selected = ismember( ...
        string({raw.learnerType}), ...
        suite.c2CurveLearners);

    plot_final_c2_cumulative( ...
        raw(selected), fullfile( ...
            figureFolder, ...
            "Figure_C2_running_performance.png"));

    plot_final_c2_endpoints( ...
        tableC2, fullfile( ...
            figureFolder, ...
            "Figure_C2_endpoint_tradeoff.png"));

    outputs.outputRoot = outputRoot;
    outputs.tableC2 = tableC2;
    outputs.safePoint = safePoint;

end


function name = final_display_name(learner)

    if learner == "dpact_safe"
        name = "D-PACT-Safe95";
    else
        name = get_learner_display_name(learner);
    end

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
