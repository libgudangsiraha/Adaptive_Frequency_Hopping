function outputs = run_dynamic_hit_pareto_scan(mode)
%RUN_DYNAMIC_HIT_PARETO_SCAN Calibrated D-PACT hit-risk Pareto scan.
%
% Examples:
%   outputs = run_dynamic_hit_pareto_scan("smoke");
%   outputs = run_dynamic_hit_pareto_scan("quick");
%   outputs = run_dynamic_hit_pareto_scan("full");
%
% The scan maximizes goodput and minimizes empirical jam-hit. It writes
% three recommended points:
%   throughput : maximum-goodput Pareto point
%   balanced   : closest Pareto point to the normalized ideal
%   low_risk   : minimum-risk Pareto point retaining >=95% max goodput

    if nargin < 1
        mode = "quick";
    end

    projectRoot = setup_paths();
    suite = get_dynamic_hit_pareto_config(mode);

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
    cfg.environment_regime = "stochastic";
    cfg.reward_mode = "outage_capped";
    cfg.dynamic_prediction_risk_mode = "hit_probability";

    cfg.resume = true;
    cfg.use_parallel = true;
    cfg.parallel_workers = 0;
    cfg.checkpoint_root = checkpointFolder;
    cfg.store_full_histories = false;
    cfg.store_metric_timeseries = false;

    numPoints = numel(suite.betaGrid) * numel(suite.nuGrid);
    rows = cell(numPoints, 1);
    raw = cell(numPoints, 1);
    pointIndex = 0;

    fprintf("\n########################################\n");
    fprintf("Dynamic hit-risk Pareto scan: %s\n", mode);
    fprintf("T = %d | seeds = %d | M_jam = %d\n", ...
        cfg.T, numel(cfg.seedList), cfg.M_jam);
    fprintf("Points = %d\n", numPoints);
    fprintf("########################################\n");

    for betaIndex = 1:numel(suite.betaGrid)
        for nuIndex = 1:numel(suite.nuGrid)

            pointIndex = pointIndex + 1;
            beta = suite.betaGrid(betaIndex);
            nu = suite.nuGrid(nuIndex);

            cfgRun = cfg;
            cfgRun.detect_beta = beta;
            cfgRun.explore_nu = nu;

            fprintf("\n===== Point %d / %d: beta=%g, nu=%g =====\n", ...
                pointIndex, numPoints, beta, nu);

            multi = run_multi_seed_pair( ...
                cfgRun, "dpact_detect", suite.adversaryType);

            raw{pointIndex} = multi;
            rows{pointIndex} = pareto_summary_row( ...
                multi, beta, nu);

            partial = vertcat(rows{1:pointIndex});
            writetable(partial, fullfile( ...
                tableFolder, "Table_P1_partial.csv"));

            save(fullfile(rawFolder, "P1_partial.mat"), ...
                "raw", "rows", "cfg", "suite", "-v7.3");
        end
    end

    tableP1 = vertcat(rows{:});
    tableP1.IsPareto = identify_pareto_points( ...
        tableP1.GoodputMbps, tableP1.EmpiricalJamHit);

    recommended = select_recommended_points(tableP1);
    tableP2 = recommended.table;

    baseIndex = find( ...
        tableP1.Beta == 0 & tableP1.Nu == 0, ...
        1, "first");

    if isempty(baseIndex)
        error("The Pareto grid must include beta=0, nu=0.");
    end

    tableP3 = paired_effects_vs_base( ...
        tableP1, raw, baseIndex);

    [baselineTable, baselineRaw] = run_baselines( ...
        cfg, suite);

    write_table_bundle(tableP1, fullfile( ...
        tableFolder, "Table_P1_dynamic_hit_pareto"));

    write_table_bundle(tableP2, fullfile( ...
        tableFolder, "Table_P2_recommended_operating_points"));

    write_table_bundle(tableP3, fullfile( ...
        tableFolder, "Table_P3_effects_vs_base"));

    write_table_bundle(baselineTable, fullfile( ...
        tableFolder, "Table_P4_pareto_baselines"));

    save(fullfile(rawFolder, "P1_dynamic_hit_pareto.mat"), ...
        "raw", "baselineRaw", "tableP1", "tableP2", ...
        "tableP3", "baselineTable", "cfg", "suite", "-v7.3");

    plot_dynamic_hit_pareto( ...
        tableP1, tableP2, baselineTable, fullfile( ...
            figureFolder, "Figure_P1_dynamic_hit_pareto.png"));

    reportPath = fullfile(outputRoot, "PARETO_RECOMMENDATION.md");
    write_pareto_recommendation( ...
        reportPath, tableP2, suite);

    outputs.outputRoot = outputRoot;
    outputs.tableP1 = tableP1;
    outputs.tableP2 = tableP2;
    outputs.tableP3 = tableP3;
    outputs.baselineTable = baselineTable;
    outputs.reportPath = reportPath;

    fprintf("\nDynamic hit-risk Pareto scan completed.\n");
    fprintf("Recommended points: %s\n", ...
        fullfile(tableFolder, ...
            "Table_P2_recommended_operating_points.csv"));

end


function row = pareto_summary_row(multi, beta, nu)

    s = multi.summary;

    row = table( ...
        beta, ...
        nu, ...
        s.meanAvgReward, ...
        s.ci95AvgReward, ...
        s.meanGoodputMbps, ...
        s.ci95GoodputMbps, ...
        s.meanPdr, ...
        s.ci95Pdr, ...
        s.meanOverlap, ...
        s.ci95Overlap, ...
        s.meanExpectedJamHit, ...
        s.ci95ExpectedJamHit, ...
        s.meanJamHitRate, ...
        s.ci95JamHitRate, ...
        s.meanJamCalibrationGap, ...
        s.ci95JamCalibrationGap, ...
        s.meanMasterLcMass, ...
        s.meanMasterLocalMass, ...
        s.meanMasterEffectiveCount, ...
        s.meanRuntime, ...
        'VariableNames', { ...
            'Beta', ...
            'Nu', ...
            'Reward', ...
            'RewardCI95', ...
            'GoodputMbps', ...
            'GoodputCI95', ...
            'PDR', ...
            'PDRCI95', ...
            'Overlap', ...
            'OverlapCI95', ...
            'ExpectedJamHit', ...
            'ExpectedJamHitCI95', ...
            'EmpiricalJamHit', ...
            'EmpiricalJamHitCI95', ...
            'CalibrationGap', ...
            'CalibrationGapCI95', ...
            'MasterLcMass', ...
            'MasterLocalMass', ...
            'MasterEffectiveCount', ...
            'RuntimeSeconds'});

end


function mask = identify_pareto_points(goodput, risk)

    numPoints = numel(goodput);
    mask = true(numPoints, 1);

    for i = 1:numPoints
        for j = 1:numPoints
            if i == j
                continue;
            end

            weaklyBetter = ...
                goodput(j) >= goodput(i) ...
                && risk(j) <= risk(i);

            strictlyBetter = ...
                goodput(j) > goodput(i) ...
                || risk(j) < risk(i);

            if weaklyBetter && strictlyBetter
                mask(i) = false;
                break;
            end
        end
    end

end


function result = select_recommended_points(tableP1)

    frontier = tableP1(tableP1.IsPareto, :);

    if isempty(frontier)
        error("No Pareto points were identified.");
    end

    throughputIndex = choose_max_goodput(frontier);
    throughputRow = frontier(throughputIndex, :);

    balancedIndex = choose_balanced(frontier);
    balancedRow = frontier(balancedIndex, :);

    maxGoodput = max(frontier.GoodputMbps);
    eligible = frontier.GoodputMbps >= 0.95 * maxGoodput;

    lowRiskPool = frontier(eligible, :);
    lowRiskIndex = choose_min_risk(lowRiskPool);
    lowRiskRow = lowRiskPool(lowRiskIndex, :);

    output = [throughputRow; balancedRow; lowRiskRow];
    output.Label = [ ...
        "throughput"; ...
        "balanced"; ...
        "low_risk"];

    output = movevars(output, "Label", "Before", "Beta");

    result.table = output;

end


function index = choose_max_goodput(inputTable)

    maxValue = max(inputTable.GoodputMbps);
    candidates = find( ...
        abs(inputTable.GoodputMbps - maxValue) <= 1e-12);

    [~, local] = min(inputTable.EmpiricalJamHit(candidates));
    index = candidates(local);

end


function index = choose_min_risk(inputTable)

    minValue = min(inputTable.EmpiricalJamHit);
    candidates = find( ...
        abs(inputTable.EmpiricalJamHit - minValue) <= 1e-12);

    [~, local] = max(inputTable.GoodputMbps(candidates));
    index = candidates(local);

end


function index = choose_balanced(frontier)

    goodput = frontier.GoodputMbps;
    risk = frontier.EmpiricalJamHit;

    goodputRange = max(goodput) - min(goodput);
    riskRange = max(risk) - min(risk);

    if goodputRange <= eps
        normalizedGoodputLoss = zeros(size(goodput));
    else
        normalizedGoodputLoss = ...
            (max(goodput) - goodput) / goodputRange;
    end

    if riskRange <= eps
        normalizedRisk = zeros(size(risk));
    else
        normalizedRisk = ...
            (risk - min(risk)) / riskRange;
    end

    score = sqrt( ...
        normalizedGoodputLoss .^ 2 ...
        + normalizedRisk .^ 2);

    [~, index] = min(score);

end


function tableP3 = paired_effects_vs_base( ...
    tableP1, raw, baseIndex)

    rows = cell(height(tableP1), 1);
    base = raw{baseIndex};

    for index = 1:height(tableP1)

        current = raw{index};

        [goodputEffect, goodputCI] = mean_ci( ...
            current.avgGoodputMbps ...
            - base.avgGoodputMbps);

        [pdrEffect, pdrCI] = mean_ci( ...
            current.pdr - base.pdr);

        [hitEffect, hitCI] = mean_ci( ...
            current.jamHitRate ...
            - base.jamHitRate);

        [expectedEffect, expectedCI] = mean_ci( ...
            current.expectedJamHit ...
            - base.expectedJamHit);

        rows{index} = table( ...
            tableP1.Beta(index), ...
            tableP1.Nu(index), ...
            goodputEffect, ...
            goodputCI, ...
            pdrEffect, ...
            pdrCI, ...
            expectedEffect, ...
            expectedCI, ...
            hitEffect, ...
            hitCI, ...
            'VariableNames', { ...
                'Beta', ...
                'Nu', ...
                'GoodputEffectVsBase', ...
                'GoodputEffectVsBaseCI95', ...
                'PDREffectVsBase', ...
                'PDREffectVsBaseCI95', ...
                'ExpectedHitEffectVsBase', ...
                'ExpectedHitEffectVsBaseCI95', ...
                'EmpiricalHitEffectVsBase', ...
                'EmpiricalHitEffectVsBaseCI95'});
    end

    tableP3 = vertcat(rows{:});

end


function [baselineTable, baselineRaw] = run_baselines(cfg, suite)

    baselineRows = cell( ...
        numel(suite.baselineLearners), 1);

    baselineRaw = cell( ...
        numel(suite.baselineLearners), 1);

    for index = 1:numel(suite.baselineLearners)

        learner = suite.baselineLearners(index);

        result = run_multi_seed_pair( ...
            cfg, learner, suite.adversaryType);

        baselineRaw{index} = result;
        s = result.summary;

        baselineRows{index} = table( ...
            get_learner_display_name(learner), ...
            s.meanGoodputMbps, ...
            s.ci95GoodputMbps, ...
            s.meanPdr, ...
            s.ci95Pdr, ...
            s.meanOverlap, ...
            s.ci95Overlap, ...
            s.meanExpectedJamHit, ...
            s.ci95ExpectedJamHit, ...
            s.meanJamHitRate, ...
            s.ci95JamHitRate, ...
            'VariableNames', { ...
                'Variant', ...
                'GoodputMbps', ...
                'GoodputCI95', ...
                'PDR', ...
                'PDRCI95', ...
                'Overlap', ...
                'OverlapCI95', ...
                'ExpectedJamHit', ...
                'ExpectedJamHitCI95', ...
                'EmpiricalJamHit', ...
                'EmpiricalJamHitCI95'});
    end

    baselineTable = vertcat(baselineRows{:});

end


function write_pareto_recommendation( ...
    outputPath, tableP2, suite)

    fileId = fopen(outputPath, "w");

    if fileId < 0
        warning("Could not create Pareto recommendation.");
        return;
    end

    cleanup = onCleanup(@() fclose(fileId));

    fprintf(fileId, "# Dynamic hit-risk operating points\n\n");
    fprintf(fileId, ...
        "- Horizon: %d\n- Seeds: %d\n- Attack budget: %d\n\n", ...
        suite.T, numel(suite.seedList), suite.attackBudget);

    for index = 1:height(tableP2)
        fprintf(fileId, "## %s\n\n", tableP2.Label(index));
        fprintf(fileId, "- beta: %.6g\n", tableP2.Beta(index));
        fprintf(fileId, "- nu: %.6g\n", tableP2.Nu(index));
        fprintf(fileId, "- goodput: %.6f Mbps\n", ...
            tableP2.GoodputMbps(index));
        fprintf(fileId, "- empirical jam-hit: %.6f\n", ...
            tableP2.EmpiricalJamHit(index));
        fprintf(fileId, "- PDR: %.6f\n\n", ...
            tableP2.PDR(index));
    end

    fprintf(fileId, ...
        "C3 uses the `balanced` point by default. " ...
        "It can also be run with `throughput` or `low_risk`.\n");

end


function [meanValue, ci95] = mean_ci(values)

    values = values(:);
    values = values(isfinite(values));

    if isempty(values)
        meanValue = NaN;
        ci95 = NaN;
        return;
    end

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
