function outputs = run_dynamic_safe_projection_scan(mode)
%RUN_DYNAMIC_SAFE_PROJECTION_SCAN Risk-constrained D-PACT experiment.

    if nargin < 1
        mode = "quick";
    end

    projectRoot = setup_paths();
    suite = get_dynamic_safe_projection_config(mode);

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
    cfg.M_jam = suite.attackBudget;
    cfg.sweep_width = suite.attackBudget;
    cfg.environment_regime = "stochastic";
    cfg.reward_mode = "outage_capped";
    cfg.dynamic_prediction_risk_mode = "hit_probability";
    cfg.detect_beta = suite.beta;
    cfg.explore_nu = suite.nu;

    cfg.resume = true;
    cfg.use_parallel = true;
    cfg.parallel_workers = 0;
    cfg.checkpoint_root = checkpointFolder;
    cfg.store_full_histories = false;
    cfg.store_metric_timeseries = false;

    unconstrained = run_multi_seed_pair( ...
        cfg, "dpact_detect", suite.scanAdversary);

    scanRows = cell(numel(suite.tauGrid), 1);
    scanRaw = cell(numel(suite.tauGrid), 1);

    for index = 1:numel(suite.tauGrid)

        tau = suite.tauGrid(index);
        cfgRun = cfg;
        cfgRun.dynamic_safe_tau = tau;

        fprintf("\n===== D-PACT-Safe tau = %.4f =====\n", tau);

        multi = run_multi_seed_pair( ...
            cfgRun, "dpact_safe", suite.scanAdversary);

        scanRaw{index} = multi;
        scanRows{index} = safe_summary_row( ...
            multi, tau, "scan", suite.scanAdversary);

        partial = vertcat(scanRows{1:index});
        writetable(partial, fullfile( ...
            tableFolder, "Table_S1_partial.csv"));

        save(fullfile(rawFolder, "S1_partial.mat"), ...
            "scanRaw", "scanRows", "cfg", "suite", "-v7.3");
    end

    tableS1 = vertcat(scanRows{:});
    tableS1.IsPareto = identify_pareto_points( ...
        tableS1.GoodputMbps, tableS1.ExpectedJamHit);

    tableS2 = select_safe_points( ...
        tableS1, unconstrained.summary.meanGoodputMbps);

    tableS3 = paired_effects_vs_unconstrained( ...
        tableS1, scanRaw, unconstrained);

    selectedLabels = [ ...
        "balanced"; ...
        "strict_safe"; ...
        "safe95"];

    numEvaluationRows = ...
        numel(suite.evaluationAdversaries) ...
        * (numel(suite.referenceLearners) ...
           + numel(selectedLabels));

    evalRows = cell(numEvaluationRows, 1);
    evalRaw = cell(numEvaluationRows, 1);
    rowIndex = 0;

    for adversaryIndex = 1:numel(suite.evaluationAdversaries)

        adversary = suite.evaluationAdversaries(adversaryIndex);

        for learnerIndex = 1:numel(suite.referenceLearners)

            learner = suite.referenceLearners(learnerIndex);
            multi = run_multi_seed_pair(cfg, learner, adversary);

            rowIndex = rowIndex + 1;
            evalRaw{rowIndex, 1} = multi; %#ok<AGROW>
            evalRows{rowIndex, 1} = safe_summary_row( ... %#ok<AGROW>
                multi, NaN, get_learner_display_name(learner), adversary);
        end

        for labelIndex = 1:numel(selectedLabels)

            label = selectedLabels(labelIndex);

            labelColumn = strtrim(string(tableS2.Label));
            match = labelColumn == label;

            if ~any(match)
                error( ...
                    "Recommended Safe point '%s' was not found. " ...
                    + "Available labels: %s", ...
                    label, ...
                    strjoin(labelColumn, ", "));
            end

            selectedIndex = find(match, 1, "first");
            selected = tableS2(selectedIndex, :);

            cfgRun = cfg;
            cfgRun.dynamic_safe_tau = selected.Tau;

            multi = run_multi_seed_pair( ...
                cfgRun, "dpact_safe", adversary);

            rowIndex = rowIndex + 1;
            evalRaw{rowIndex, 1} = multi;
            evalRows{rowIndex, 1} = safe_summary_row( ...
                multi, selected.Tau, ...
                "D-PACT-Safe-" + label, adversary);
        end
    end

    tableS4 = vertcat(evalRows{:});

    write_table_bundle(tableS1, fullfile( ...
        tableFolder, "Table_S1_tau_scan"));

    write_table_bundle(tableS2, fullfile( ...
        tableFolder, "Table_S2_recommended_safe_points"));

    write_table_bundle(tableS3, fullfile( ...
        tableFolder, "Table_S3_effects_vs_unconstrained"));

    write_table_bundle(tableS4, fullfile( ...
        tableFolder, "Table_S4_cross_attacker_safe"));

    save(fullfile(rawFolder, "S1_dynamic_safe_projection.mat"), ...
        "scanRaw", "evalRaw", "unconstrained", ...
        "tableS1", "tableS2", "tableS3", "tableS4", ...
        "cfg", "suite", "-v7.3");

    plot_dynamic_safe_frontier( ...
        tableS1, tableS2, unconstrained, fullfile( ...
            figureFolder, "Figure_S1_safe_frontier.png"));

    plot_dynamic_safe_cross_attacker( ...
        tableS4, fullfile( ...
            figureFolder, "Figure_S2_safe_cross_attacker.png"));

    outputs.outputRoot = outputRoot;
    outputs.tableS1 = tableS1;
    outputs.tableS2 = tableS2;
    outputs.tableS3 = tableS3;
    outputs.tableS4 = tableS4;

end


function row = safe_summary_row(multi, tau, label, adversary)

    s = multi.summary;

    row = table( ...
        string(label), ...
        string(get_adversary_display_name(adversary)), ...
        tau, ...
        s.meanGoodputMbps, ...
        s.ci95GoodputMbps, ...
        s.meanPdr, ...
        s.ci95Pdr, ...
        s.meanExpectedJamHit, ...
        s.ci95ExpectedJamHit, ...
        s.meanJamHitRate, ...
        s.ci95JamHitRate, ...
        s.meanRiskProjectionActivationRate, ...
        s.meanAvgRiskProjectionKl, ...
        s.meanAvgPreProjectionHitRisk, ...
        s.meanAvgPostProjectionHitRisk, ...
        s.meanMaxRiskProjectionViolation, ...
        s.meanRuntime, ...
        'VariableNames', { ...
            'Label', ...
            'Adversary', ...
            'Tau', ...
            'GoodputMbps', ...
            'GoodputCI95', ...
            'PDR', ...
            'PDRCI95', ...
            'ExpectedJamHit', ...
            'ExpectedJamHitCI95', ...
            'EmpiricalJamHit', ...
            'EmpiricalJamHitCI95', ...
            'ProjectionActivationRate', ...
            'MeanProjectionKL', ...
            'PreProjectionHitRisk', ...
            'PostProjectionHitRisk', ...
            'MaxBudgetViolation', ...
            'RuntimeSeconds'});

end


function mask = identify_pareto_points(goodput, risk)

    n = numel(goodput);
    mask = true(n, 1);

    for i = 1:n
        for j = 1:n

            if i == j
                continue;
            end

            if goodput(j) >= goodput(i) ...
                    && risk(j) <= risk(i) ...
                    && (goodput(j) > goodput(i) ...
                        || risk(j) < risk(i))

                mask(i) = false;
                break;
            end
        end
    end

end


function tableS2 = select_safe_points(tableS1, unconstrainedGoodput)

    frontier = tableS1(tableS1.IsPareto, :);

    goodput = frontier.GoodputMbps;
    risk = frontier.ExpectedJamHit;

    goodputRange = max(goodput) - min(goodput);
    riskRange = max(risk) - min(risk);

    minStrictRisk = min(frontier.ExpectedJamHit);

    strictCandidates = find(abs( ...
        frontier.ExpectedJamHit - minStrictRisk) <= 1e-12);

    [~, strictLocal] = max( ...
        frontier.GoodputMbps(strictCandidates));

    strictSafeIndex = strictCandidates(strictLocal);

    if goodputRange <= eps
        goodputLoss = zeros(size(goodput));
    else
        goodputLoss = ...
            (max(goodput) - goodput) / goodputRange;
    end

    if riskRange <= eps
        normalizedRisk = zeros(size(risk));
    else
        normalizedRisk = ...
            (risk - min(risk)) / riskRange;
    end

    [~, balancedIndex] = min(sqrt( ...
        goodputLoss .^ 2 + normalizedRisk .^ 2));

    eligible = frontier.GoodputMbps ...
        >= 0.95 * unconstrainedGoodput;

    safe95Pool = frontier(eligible, :);

    if isempty(safe95Pool)
        safe95Pool = frontier;
    end

    minSafe95Risk = min(safe95Pool.ExpectedJamHit);

    safe95Candidates = find(abs( ...
        safe95Pool.ExpectedJamHit ...
        - minSafe95Risk) <= 1e-12);

    [~, safe95Local] = max( ...
        safe95Pool.GoodputMbps(safe95Candidates));

    safe95Index = safe95Candidates(safe95Local);

    tableS2 = [ ...
        frontier(balancedIndex, :); ...
        frontier(strictSafeIndex, :); ...
        safe95Pool(safe95Index, :)];

    tableS2.Label = strings(height(tableS2), 1);
    tableS2.Label(1) = "balanced";
    tableS2.Label(2) = "strict_safe";
    tableS2.Label(3) = "safe95";

    tableS2 = movevars( ...
        tableS2, "Label", "Before", "Adversary");

end


function tableS3 = paired_effects_vs_unconstrained( ...
    tableS1, scanRaw, unconstrained)

    rows = cell(height(tableS1), 1);

    for index = 1:height(tableS1)

        current = scanRaw{index};

        [goodputEffect, goodputCI] = mean_ci( ...
            current.avgGoodputMbps ...
            - unconstrained.avgGoodputMbps);

        [hitEffect, hitCI] = mean_ci( ...
            current.jamHitRate ...
            - unconstrained.jamHitRate);

        rows{index} = table( ...
            tableS1.Tau(index), ...
            goodputEffect, ...
            goodputCI, ...
            hitEffect, ...
            hitCI, ...
            'VariableNames', { ...
                'Tau', ...
                'GoodputEffectVsHit', ...
                'GoodputEffectVsHitCI95', ...
                'EmpiricalHitEffectVsHit', ...
                'EmpiricalHitEffectVsHitCI95'});
    end

    tableS3 = vertcat(rows{:});

end


function [meanValue, ci95] = mean_ci(values)

    values = values(:);
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
