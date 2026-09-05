function outputs = run_final_c3(mode)
%RUN_FINAL_C3 Final cross-attacker comparison.
%
% Unlike the older staged C3, this runner puts D-PACT-Safe95 directly in
% the same common-seed comparison as all reference learners.

    if nargin < 1
        mode = "quick";
    end

    projectRoot = setup_paths();
    suite = get_final_c1_c4_config(mode);
    safePoint = resolve_final_safe_point( ...
        projectRoot, suite);

    outputRoot = fullfile( ...
        projectRoot, "results", "final_c3", char(mode));

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
    cfgBase.seedList = suite.c3Seeds;
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

    totalRows = ...
        numel(suite.c3Adversaries) ...
        * numel(suite.c3Learners);

    rows = cell(totalRows, 1);
    raw = cell(totalRows, 1);
    rowIndex = 0;

    for adversaryIndex = 1:numel(suite.c3Adversaries)

        adversary = suite.c3Adversaries(adversaryIndex);

        for learnerIndex = 1:numel(suite.c3Learners)

            learner = suite.c3Learners(learnerIndex);
            rowIndex = rowIndex + 1;

            fprintf("\n===== FINAL C3 | %s | %s =====\n", ...
                get_adversary_display_name(adversary), ...
                get_learner_display_name(learner));

            result = run_multi_seed_pair( ...
                cfgBase, learner, adversary);

            raw{rowIndex} = result;

            extra.Tau = NaN;
            if learner == "dpact_safe"
                extra.Tau = safePoint.tau;
            end

            rows{rowIndex} = ...
                build_communication_summary_row( ...
                    result, extra);

            rows{rowIndex}.Learner = ...
                final_display_name(learner);

            partial = vertcat(rows{1:rowIndex});
            writetable(partial, fullfile( ...
                tableFolder, "Table_C3_partial.csv"));

            save(fullfile(rawFolder, "C3_partial.mat"), ...
                "rows", "raw", "cfgBase", ...
                "suite", "safePoint", "-v7.3");
        end
    end

    tableC3 = vertcat(rows{:});

    write_table_bundle(tableC3, fullfile( ...
        tableFolder, "Table_C3_cross_attacker"));

    save(fullfile(rawFolder, "C3_final.mat"), ...
        "tableC3", "raw", "cfgBase", ...
        "suite", "safePoint", "-v7.3");

    plot_final_c3_heatmaps( ...
        tableC3, fullfile( ...
            figureFolder, ...
            "Figure_C3_cross_attacker_heatmaps.png"));

    plot_final_c3_tradeoff( ...
        tableC3, fullfile( ...
            figureFolder, ...
            "Figure_C3_cross_attacker_tradeoff.png"));

    outputs.outputRoot = outputRoot;
    outputs.tableC3 = tableC3;
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
