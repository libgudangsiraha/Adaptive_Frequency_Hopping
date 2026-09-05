function outputs = run_pact_afh_communication_module(moduleName, mode)
%RUN_PACT_AFH_COMMUNICATION_MODULE Resumable v2 communication modules.
%
% Examples:
%   run_pact_afh_communication_module("C2", "full")
%   run_pact_afh_communication_module("C6", "full")
%   run_pact_afh_communication_module("ALL", "quick")
%
% Every seed is checkpointed immediately. Re-running the same command
% resumes from the first unfinished seed.

    if nargin < 1, moduleName = "ALL"; end
    if nargin < 2, mode = "smoke"; end

    moduleName = upper(string(moduleName));
    projectRoot = setup_paths();
    suite = get_communication_suite_config(mode);

    outputRoot = fullfile(projectRoot, suite.outputRoot);
    rawFolder = fullfile(outputRoot, "raw");
    tableFolder = fullfile(outputRoot, "tables");
    figureFolder = fullfile(outputRoot, "figures");
    checkpointFolder = fullfile(outputRoot, "checkpoints");
    ensure_folder(rawFolder); ensure_folder(tableFolder);
    ensure_folder(figureFolder); ensure_folder(checkpointFolder);

    cfgBase = get_base_config();
    cfgBase.T = suite.T;
    cfgBase.detect_beta = suite.defaultBeta;
    cfgBase.explore_nu = suite.defaultNu;
    cfgBase.folpetti_mc_samples = suite.folpettiMcSamples;
    cfgBase.checkpoint_root = checkpointFolder;
    cfgBase.resume = true;
    cfgBase.use_parallel = true;
    cfgBase.reward_mode = "outage_capped";
    cfgBase.pact_expert_bank_mode = "hybrid";

    fprintf("\n########################################\n");
    fprintf("PACT-AFH v2 module: %s | mode: %s\n", moduleName, mode);
    fprintf("Reward model: %s\n", cfgBase.reward_mode);
    fprintf("Output: %s\n", outputRoot);
    fprintf("########################################\n");

    modules = resolve_modules(moduleName);
    outputs = struct();

    for module = modules
        switch module
            case "C2"
                outputs.C2 = run_c2(cfgBase, suite, rawFolder, ...
                    tableFolder, figureFolder);
            case "C3"
                outputs.C3 = run_c3(cfgBase, suite, rawFolder, ...
                    tableFolder, figureFolder);
            case "C4"
                outputs.C4 = run_c4(cfgBase, suite, rawFolder, ...
                    tableFolder, figureFolder);
            case "C5"
                outputs.C5 = run_c5(cfgBase, suite, rawFolder, tableFolder);
            case "PARETO"
                outputs.Pareto = run_pareto(cfgBase, suite, rawFolder, ...
                    tableFolder, figureFolder);
            case "ROBUSTNESS"
                outputs.Robustness = run_robustness( ...
                    cfgBase, suite, rawFolder, tableFolder, figureFolder);
            case "C6"
                outputs.C6 = run_c6(cfgBase, suite, rawFolder, ...
                    tableFolder, figureFolder);
        end
    end

    tableC1 = build_system_parameter_table(cfgBase, suite);
    write_table_bundle(tableC1, fullfile( ...
        tableFolder, "Table_C1_system_parameters"));
    outputs.C1 = tableC1;
    write_suite_readme(outputRoot, mode, cfgBase, suite);

    fprintf("\nModule execution completed. Results: %s\n", outputRoot);

end


function modules = resolve_modules(moduleName)

    if moduleName == "ALL"
        modules = ["C2", "C3", "C4", "C5", ...
            "PARETO", "ROBUSTNESS", "C6"];
    else
        valid = ["C2", "C3", "C4", "C5", ...
            "PARETO", "ROBUSTNESS", "C6"];
        if ~ismember(moduleName, valid)
            error("Unknown communication module: %s", moduleName);
        end
        modules = moduleName;
    end

end


function output = run_c2(cfgBase, suite, rawFolder, tableFolder, figureFolder)

    fprintf("\n===== C2: Main packet-aligned performance =====\n");
    cfg = with_seeds(cfgBase, suite.mainSeeds);
    cfg.store_full_histories = false;
    cfg.store_metric_timeseries = true;

    rows = cell(numel(suite.mainLearners), 1);
    raw = repmat(struct('name', "", 'multiResults', []), ...
        numel(suite.mainLearners), 1);

    for index = 1:numel(suite.mainLearners)
        learner = suite.mainLearners(index);
        result = run_multi_seed_pair(cfg, learner, "contextual_expert");
        rows{index} = build_communication_summary_row(result);
        raw(index).name = get_learner_display_name(learner);
        raw(index).multiResults = result;
        tableC2 = vertcat(rows{~cellfun(@isempty, rows)});
        persist_module("C2_main", raw, tableC2, rawFolder, tableFolder);
    end

    selected = ismember(string({raw.name}), [ ...
        "EXP3", "LC-Tsallis-INF-Online", ...
        "LC-Tsallis-INF-Pool", "PACT-AFH-Base", "PACT-AFH"]);
    plot_cumulative_communication_v2(raw(selected), fullfile( ...
        figureFolder, "Figure_C2_cumulative_communication_v2.png"));
    plot_goodput_risk_scatter(tableC2, fullfile( ...
        figureFolder, "Figure_C2b_goodput_risk_scatter.png"));

    output.table = tableC2; output.raw = raw;

end


function output = run_c3(cfgBase, suite, rawFolder, tableFolder, figureFolder)

    fprintf("\n===== C3: External-attacker robustness =====\n");
    cfgBase = with_seeds(cfgBase, suite.externalSeeds);
    cfgBase.store_full_histories = false;
    cfgBase.store_metric_timeseries = false;
    rows = cell(numel(suite.externalAdversaries) ...
        * numel(suite.externalLearners), 1);
    raw = cell(size(rows)); rowIndex = 0;

    for a = 1:numel(suite.externalAdversaries)
        cfg = cfgBase;
        cfg.M_jam = suite.externalAttackBudget;
        cfg.sweep_width = suite.externalAttackBudget;
        adversary = suite.externalAdversaries(a);

        for l = 1:numel(suite.externalLearners)
            rowIndex = rowIndex + 1;
            learner = suite.externalLearners(l);
            result = run_multi_seed_pair(cfg, learner, adversary);
            raw{rowIndex} = result;
            rows{rowIndex} = build_communication_summary_row(result);
            tableC3 = vertcat(rows{~cellfun(@isempty, rows)});
            persist_module("C3_external_attackers", raw, ...
                tableC3, rawFolder, tableFolder);
        end
    end

    plot_external_attacker_heatmap(tableC3, fullfile( ...
        figureFolder, "Figure_C4_external_attacker_heatmap.png"));
    output.table = tableC3; output.raw = raw;

end


function output = run_c4(cfgBase, suite, rawFolder, tableFolder, figureFolder)

    fprintf("\n===== C4: Mechanism ablation =====\n");
    cfg = with_seeds(cfgBase, suite.ablationSeeds);
    cfg.store_full_histories = false;
    cfg.store_metric_timeseries = false;
    rows = cell(numel(suite.ablationLearners), 1);
    raw = cell(size(rows));

    for index = 1:numel(suite.ablationLearners)
        learner = suite.ablationLearners(index);
        result = run_multi_seed_pair(cfg, learner, "contextual_expert");
        raw{index} = result;
        extra.BaseRisk = result.summary.meanBaseRisk;
        extra.BaseRiskCI95 = result.summary.ci95BaseRisk;
        extra.ExplorationRisk = result.summary.meanExplorationRisk;
        extra.ExplorationRiskCI95 = result.summary.ci95ExplorationRisk;
        extra.LinearFamilyMass = result.summary.meanLinearFamilyMass;
        extra.PartitionFamilyMass = result.summary.meanPartitionFamilyMass;
        rows{index} = build_communication_summary_row(result, extra);
        tableC4 = vertcat(rows{~cellfun(@isempty, rows)});
        persist_module("C4_ablation", raw, tableC4, rawFolder, tableFolder);
    end

    plot_risk_decomposition(tableC4, fullfile( ...
        figureFolder, "Figure_C5_risk_decomposition.png"));
    output.table = tableC4; output.raw = raw;

end


function output = run_c5(cfgBase, suite, rawFolder, tableFolder)

    fprintf("\n===== C5: Environment-regime robustness =====\n");
    cfgBase = with_seeds(cfgBase, suite.regimeSeeds);
    cfgBase.store_full_histories = false;
    cfgBase.store_metric_timeseries = false;
    rows = cell(numel(suite.regimeNames) ...
        * numel(suite.regimeLearners), 1);
    raw = cell(size(rows)); rowIndex = 0;

    for r = 1:numel(suite.regimeNames)
        cfg = cfgBase;
        cfg.environment_regime = suite.regimeEnvironment(r);
        adversary = suite.regimeAdversaries(r);

        for l = 1:numel(suite.regimeLearners)
            rowIndex = rowIndex + 1;
            result = run_multi_seed_pair( ...
                cfg, suite.regimeLearners(l), adversary);
            raw{rowIndex} = result;
            rows{rowIndex} = build_communication_summary_row(result);
            rows{rowIndex}.Regime = suite.regimeNames(r);
            tableC5 = vertcat(rows{~cellfun(@isempty, rows)});
            persist_module("C5_regimes", raw, tableC5, rawFolder, tableFolder);
        end
    end

    output.table = tableC5; output.raw = raw;

end


function output = run_pareto(cfgBase, suite, rawFolder, tableFolder, figureFolder)

    fprintf("\n===== Pareto: beta-nu operating points =====\n");
    cfgBase = with_seeds(cfgBase, suite.paretoSeeds);
    cfgBase.store_full_histories = false;
    cfgBase.store_metric_timeseries = false;
    rows = cell(numel(suite.betaGrid) * numel(suite.nuGrid), 1);
    raw = cell(size(rows)); rowIndex = 0;

    for b = 1:numel(suite.betaGrid)
        for n = 1:numel(suite.nuGrid)
            rowIndex = rowIndex + 1;
            cfg = cfgBase;
            cfg.detect_beta = suite.betaGrid(b);
            cfg.explore_nu = suite.nuGrid(n);
            result = run_multi_seed_pair( ...
                cfg, "bc_detect", "contextual_expert");
            raw{rowIndex} = result;
            extra.Beta = suite.betaGrid(b); extra.Nu = suite.nuGrid(n);
            rows{rowIndex} = build_communication_summary_row(result, extra);
            tablePareto = vertcat(rows{~cellfun(@isempty, rows)});
            persist_module("Pareto_beta_nu", raw, tablePareto, ...
                rawFolder, tableFolder);
        end
    end

    % Baseline points use the same seed count for a fair Pareto figure.
    baselineLearners = ["lc_inf_online", "lc_inf_pool", ...
        "risk_exp4", "aufh_exp3pp"];
    baselineRows = cell(numel(baselineLearners), 1);
    baselineRaw = cell(size(baselineRows));
    for index = 1:numel(baselineLearners)
        result = run_multi_seed_pair(cfgBase, ...
            baselineLearners(index), "contextual_expert");
        baselineRaw{index} = result;
        baselineRows{index} = build_communication_summary_row(result);
    end
    baselineTable = vertcat(baselineRows{:});
    save(fullfile(rawFolder, "Pareto_baselines.mat"), ...
        "baselineRaw", "baselineTable", "-v7.3");
    write_table_bundle(baselineTable, fullfile( ...
        tableFolder, "Pareto_baselines"));

    plot_communication_pareto(tablePareto, baselineTable, fullfile( ...
        figureFolder, "Figure_C1_goodput_overlap_pareto.png"));
    output.table = tablePareto; output.baselines = baselineTable;

end


function output = run_robustness(cfgBase, suite, rawFolder, tableFolder, figureFolder)

    fprintf("\n===== Robustness: JSR, predictor power, attack budget =====\n");
    cfgBase = with_seeds(cfgBase, suite.robustnessSeeds);
    cfgBase.store_full_histories = false;
    cfgBase.store_metric_timeseries = false;
    learners = ["exp3", "lc_inf_online", "aufh_exp3pp", ...
        "bc_nodetect", "bc_detect"];

    rows = {}; raw = {}; rowIndex = 0;
    for j = 1:numel(suite.jsrDbGrid)
        cfg = cfgBase;
        cfg.jam_strength = cfg.P_tx * 10^(suite.jsrDbGrid(j) / 10);
        for l = 1:numel(learners)
            rowIndex = rowIndex + 1;
            result = run_multi_seed_pair( ...
                cfg, learners(l), "contextual_expert");
            raw{rowIndex, 1} = result; %#ok<AGROW>
            extra.JSRdB = suite.jsrDbGrid(j);
            extra.PredictorPower = cfg.predictor_power;
            extra.AttackBudget = cfg.M_jam;
            rows{rowIndex, 1} = build_communication_summary_row( ...
                result, extra); %#ok<AGROW>
            tableRobust = vertcat(rows{:});
            persist_module("Robustness_sweeps", raw, tableRobust, ...
                rawFolder, tableFolder);
        end
    end

    focusLearners = ["lc_inf_online", "bc_nodetect", "bc_detect"];
    for power = suite.predictorPowerGrid
        for budget = suite.attackBudgetGrid
            cfg = cfgBase;
            cfg.predictor_power = power;
            cfg.M_jam = budget;
            for l = 1:numel(focusLearners)
                rowIndex = rowIndex + 1;
                result = run_multi_seed_pair( ...
                    cfg, focusLearners(l), "contextual_expert");
                raw{rowIndex, 1} = result; %#ok<AGROW>
                extra.JSRdB = NaN;
                extra.PredictorPower = power;
                extra.AttackBudget = budget;
                rows{rowIndex, 1} = build_communication_summary_row( ...
                    result, extra); %#ok<AGROW>
                tableRobust = vertcat(rows{:});
                persist_module("Robustness_sweeps", raw, tableRobust, ...
                    rawFolder, tableFolder);
            end
        end
    end

    plot_jsr_robustness(tableRobust(isfinite(tableRobust.JSRdB), :), ...
        fullfile(figureFolder, "Figure_C3_pdr_sinr_vs_jsr.png"));
    plot_attack_strength_crossover(tableRobust, fullfile( ...
        figureFolder, "Figure_C7_attack_strength_crossover.png"));
    output.table = tableRobust; output.raw = raw;

end


function output = run_c6(cfgBase, suite, rawFolder, tableFolder, figureFolder)

    fprintf("\n===== C6: Fast resumable scaling =====\n");
    cfgBase = with_seeds(cfgBase, suite.scalingSeeds);
    cfgBase.store_full_histories = false;
    cfgBase.store_metric_timeseries = false;
    learners = ["lc_inf_online", "aufh_exp3pp", ...
        "bc_nodetect", "bc_detect"];
    rows = {}; raw = {}; rowIndex = 0;

    for K = suite.KGrid
        cfg = cfgBase;
        cfg.K = K;
        cfg.fc_GHz = linspace(12, 18, K);
        cfg.fc = cfg.fc_GHz * 1e9;
        for l = 1:numel(learners)
            rowIndex = rowIndex + 1;
            result = run_multi_seed_pair( ...
                cfg, learners(l), "contextual_expert");
            raw{rowIndex, 1} = result; %#ok<AGROW>
            extra.ScaleType = "K";
            extra.ScaleValue = K; extra.K = K; extra.T = cfg.T;
            rows{rowIndex, 1} = build_communication_summary_row( ...
                result, extra); %#ok<AGROW>
            tableC6 = vertcat(rows{:});
            persist_module("C6_scaling", raw, tableC6, ...
                rawFolder, tableFolder);
        end
    end

    for T = suite.TGrid
        cfg = cfgBase; cfg.T = T;
        for l = 1:numel(learners)
            rowIndex = rowIndex + 1;
            result = run_multi_seed_pair( ...
                cfg, learners(l), "contextual_expert");
            raw{rowIndex, 1} = result; %#ok<AGROW>
            extra.ScaleType = "T";
            extra.ScaleValue = T; extra.K = cfg.K; extra.T = T;
            rows{rowIndex, 1} = build_communication_summary_row( ...
                result, extra); %#ok<AGROW>
            tableC6 = vertcat(rows{:});
            persist_module("C6_scaling", raw, tableC6, ...
                rawFolder, tableFolder);
        end
    end

    plot_scaling_results(tableC6, fullfile( ...
        figureFolder, "Figure_C6_scaling.png"));
    output.table = tableC6; output.raw = raw;

end


function cfg = with_seeds(cfg, seeds)

    cfg.seedList = seeds;
    cfg.numSeeds = numel(seeds);

end


function persist_module(name, raw, tableValue, rawFolder, tableFolder) %#ok<INUSD>
%PERSIST_MODULE Lightweight module progress snapshot.
%
% Full raw histories already live in per-seed checkpoints. Repeatedly
% rewriting them after every pair would defeat the speed improvement.

    save(fullfile(rawFolder, name + "_progress.mat"), ...
        "tableValue", "-v7.3");
    write_table_bundle(tableValue, fullfile(tableFolder, name));

end


function tableC1 = build_system_parameter_table(cfg, suite)

    parameter = [ ...
        "Number of channels K"; "Rounds T"; "Reward mode"; ...
        "MCS cap"; "SINR outage threshold"; ...
        "PACT expert bank"; "PACT beta"; "PACT nu"; ...
        "Main seeds"; "Scaling seeds"; ...
        "Checkpoint/resume"; "Parallel seeds"];
    value = [ ...
        string(cfg.K); string(cfg.T); string(cfg.reward_mode); ...
        string(cfg.mcs_cap_bps_hz) + " bit/s/Hz"; ...
        string(cfg.sinr_outage_threshold_dB) + " dB"; ...
        string(cfg.pact_expert_bank_mode); ...
        string(suite.defaultBeta); string(suite.defaultNu); ...
        string(numel(suite.mainSeeds)); ...
        string(numel(suite.scalingSeeds)); ...
        "per-seed persistent"; "enabled when toolbox available"];
    tableC1 = table(parameter, value, ...
        'VariableNames', {'Parameter', 'Value'});

end


function write_suite_readme(outputRoot, mode, cfg, suite)

    fileId = fopen(fullfile(outputRoot, "README.md"), 'w');
    if fileId < 0, return; end
    cleanup = onCleanup(@() fclose(fileId));
    fprintf(fileId, '# PACT-AFH communication v2 results\n\n');
    fprintf(fileId, '- Mode: `%s`\n', mode);
    fprintf(fileId, '- Reward: `%s`\n', cfg.reward_mode);
    fprintf(fileId, '- Expert bank: `%s`\n', cfg.pact_expert_bank_mode);
    fprintf(fileId, '- Per-seed checkpoints: enabled\n');
    fprintf(fileId, '- Parallel execution: enabled when available\n');
    fprintf(fileId, '- Main seeds: %d\n', numel(suite.mainSeeds));
    fprintf(fileId, '- C6 seeds: %d\n', numel(suite.scalingSeeds));

end


function ensure_folder(folderPath)

    if ~isfolder(folderPath), mkdir(folderPath); end

end
