function outputs = finalize_complete_communication_paper(mode)
%FINALIZE_COMPLETE_COMMUNICATION_PAPER Assemble C1-C6 paper outputs.
%
% This function never runs simulations. It requires completed result
% MAT files and copies/regenerates the final tables and figures into one
% stable folder.

    if nargin < 1
        mode = "full";
    end

    projectRoot = setup_paths();
    mode = lower(string(mode));

    outputRoot = fullfile( ...
        projectRoot, "results", ...
        "paper_complete", char(mode));

    tableFolder = fullfile(outputRoot, "tables");
    figureFolder = fullfile(outputRoot, "figures");
    rawFolder = fullfile(outputRoot, "raw");

    ensure_folder(tableFolder);
    ensure_folder(figureFolder);
    ensure_folder(rawFolder);

    c2 = load_required(fullfile( ...
        projectRoot, "results", "final_c2", char(mode), ...
        "raw", "C2_final.mat"));

    c3 = load_required(fullfile( ...
        projectRoot, "results", "final_c3", char(mode), ...
        "raw", "C3_final.mat"));

    c4 = load_required(fullfile( ...
        projectRoot, "results", "final_c4", char(mode), ...
        "raw", "C4_final.mat"));

    safe = load_required(fullfile( ...
        projectRoot, "results", ...
        "dynamic_safe_projection", char(mode), ...
        "raw", "S1_dynamic_safe_projection.mat"));

    probe = load_required(fullfile( ...
        projectRoot, "results", ...
        "dynamic_model_class_probe", char(mode), ...
        "raw", "C5M_model_class_probe.mat"));

    c5 = load_required(fullfile( ...
        projectRoot, "results", ...
        "dynamic_c5", char(mode), ...
        "raw", "C5_dynamic_safe.mat"));

    c6 = load_required(fullfile( ...
        projectRoot, "results", ...
        "dynamic_c6", char(mode), ...
        "raw", "C6_dynamic_safe.mat"));

    tableC1 = build_final_c1_table(mode);

    write_table_bundle(tableC1, fullfile( ...
        tableFolder, "Table_C1_system_parameters"));

    write_table_bundle(c2.tableC2, fullfile( ...
        tableFolder, "Table_C2_main_performance"));

    write_table_bundle(c3.tableC3, fullfile( ...
        tableFolder, "Table_C3_cross_attacker"));

    write_table_bundle(c4.tableC4, fullfile( ...
        tableFolder, "Table_C4_ablation"));

    write_table_bundle(probe.tableEffects, fullfile( ...
        tableFolder, "Table_C4b_model_selection_effects"));

    write_table_bundle(c5.tableC5, fullfile( ...
        tableFolder, "Table_C5_regime_robustness"));

    write_table_bundle(c6.tableC6, fullfile( ...
        tableFolder, "Table_C6_scaling"));

    write_table_bundle(safe.tableS1, fullfile( ...
        tableFolder, "Table_S1_safe_frontier"));

    write_table_bundle(safe.tableS2, fullfile( ...
        tableFolder, "Table_S2_safe_points"));

    plot_final_c2_cumulative( ...
        select_c2_curves(c2.raw, c2.suite), ...
        fullfile(figureFolder, "Figure_C2_running_performance"));

    plot_final_c2_endpoints( ...
        c2.tableC2, fullfile( ...
            figureFolder, "Figure_C2_endpoint_tradeoff"));

    plot_final_c3_heatmaps( ...
        c3.tableC3, fullfile( ...
            figureFolder, ...
            "Figure_C3_cross_attacker_heatmaps"));

    plot_final_c3_tradeoff( ...
        c3.tableC3, fullfile( ...
            figureFolder, ...
            "Figure_C3_cross_attacker_tradeoff"));

    plot_final_c4_ablation( ...
        c4.tableC4, fullfile( ...
            figureFolder, ...
            "Figure_C4_mechanism_ablation"));

    plot_paper_model_selection( ...
        augment_model_table(probe.tableEffects), ...
        fullfile(figureFolder, ...
            "Figure_C4b_model_selection.png"));

    plot_paper_c5_summary( ...
        c5.tableC5, fullfile( ...
            figureFolder, ...
            "Figure_C5_regime_summary.png"));

    plot_paper_c6_summary( ...
        c6.tableC6, fullfile( ...
            figureFolder, ...
            "Figure_C6_scaling.png"));

    plot_paper_safe_frontier( ...
        safe.tableS1, safe.tableS2, safe.unconstrained, ...
        fullfile(figureFolder, ...
            "Figure_S1_safe_frontier.png"));

    write_manifest(outputRoot);

    save(fullfile(rawFolder, ...
        "COMPLETE_PAPER_RESULTS.mat"), ...
        "tableC1", "c2", "c3", "c4", ...
        "safe", "probe", "c5", "c6", "-v7.3");

    outputs.outputRoot = outputRoot;
    outputs.tableC1 = tableC1;
    outputs.tableC2 = c2.tableC2;
    outputs.tableC3 = c3.tableC3;
    outputs.tableC4 = c4.tableC4;
    outputs.tableC5 = c5.tableC5;
    outputs.tableC6 = c6.tableC6;

    fprintf("\n========================================\n");
    fprintf("Complete C1-C6 paper bundle created\n");
    fprintf("========================================\n");
    fprintf("%s\n", outputRoot);

end


function output = select_c2_curves(raw, suite)

    selected = ismember( ...
        string({raw.learnerType}), ...
        suite.c2CurveLearners);

    output = raw(selected);

end


function tableModel = augment_model_table(input)

    tableModel = input;

    tableModel.LocalEffectLower95 = ...
        tableModel.LocalMinusLCGoodputMbps ...
        - tableModel.LocalMinusLCGoodputCI95;

    tableModel.DynamicEffectLower95 = ...
        tableModel.DynamicMinusLCGoodputMbps ...
        - tableModel.DynamicMinusLCGoodputCI95;

    tableModel.RecoveryPercent = NaN(height(tableModel), 1);
    tableModel.LossMitigationPercent = NaN(height(tableModel), 1);

    positive = tableModel.LocalMinusLCGoodputMbps > 0;

    tableModel.RecoveryPercent(positive) = 100 .* ...
        tableModel.DynamicMinusLCGoodputMbps(positive) ...
        ./ tableModel.LocalMinusLCGoodputMbps(positive);

    negative = tableModel.LocalMinusLCGoodputMbps < 0;

    tableModel.LossMitigationPercent(negative) = 100 .* ...
        (1 - abs(tableModel.DynamicMinusLCGoodputMbps(negative)) ...
        ./ abs(tableModel.LocalMinusLCGoodputMbps(negative)));

end


function data = load_required(pathValue)

    if ~isfile(pathValue)
        error("Required final result is missing: %s", pathValue);
    end

    data = load(pathValue);

end


function write_manifest(outputRoot)

    fileId = fopen(fullfile( ...
        outputRoot, "COMPLETE_PAPER_MANIFEST.md"), "w");

    if fileId < 0
        error("Could not write complete-paper manifest.");
    end

    cleanup = onCleanup(@() fclose(fileId));

    fprintf(fileId, "# Complete communication-paper bundle\n\n");
    fprintf(fileId, "- C1: final system parameter table\n");
    fprintf(fileId, "- C2: white-box running performance and endpoint tradeoff\n");
    fprintf(fileId, "- C3: Random, sweep, FOLPETTI, and white-box robustness\n");
    fprintf(fileId, "- C4: LC-only, Local-only, Base, Hit, and Safe ablation\n");
    fprintf(fileId, "- C4b: model-selection effects and master allocation\n");
    fprintf(fileId, "- C5: environment-regime robustness\n");
    fprintf(fileId, "- C6: channel/horizon/runtime scaling\n");
    fprintf(fileId, "- S1: Safe risk-goodput frontier\n\n");
    fprintf(fileId, ...
        "PNG files are exported at 300 dpi. PDF figures are vector " ...
        + "when supported by the installed MATLAB release.\n");

end


function ensure_folder(pathValue)

    if ~isfolder(pathValue)
        mkdir(pathValue);
    end

end
