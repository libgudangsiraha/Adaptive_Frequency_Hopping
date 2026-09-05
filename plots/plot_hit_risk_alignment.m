function plot_hit_risk_alignment(tableH1, outputPath)
%PLOT_HIT_RISK_ALIGNMENT Communication and risk-calibration comparison.

    labels = categorical( ...
        tableH1.Variant, tableH1.Variant, "Ordinal", true);

    figure;
    tiledlayout(2, 2);

    nexttile;
    bar(labels, tableH1.GoodputMbps);
    hold on;
    errorbar( ...
        1:height(tableH1), ...
        tableH1.GoodputMbps, ...
        tableH1.GoodputCI95, ...
        "k.", "LineWidth", 1);
    hold off;
    ylabel("Goodput (Mbps)");
    title("Communication performance");
    grid on;
    xtickangle(25);

    nexttile;
    bar(labels, tableH1.Overlap);
    hold on;
    errorbar( ...
        1:height(tableH1), ...
        tableH1.Overlap, ...
        tableH1.OverlapCI95, ...
        "k.", "LineWidth", 1);
    hold off;
    ylabel("Prediction overlap");
    title("Legacy q-overlap");
    grid on;
    xtickangle(25);

    nexttile;
    values = [ ...
        tableH1.ExpectedJamHit, ...
        tableH1.EmpiricalJamHit];
    bar(labels, values);
    ylabel("Jam-hit probability");
    title("Expected and empirical jam hit");
    legend(["Expected", "Empirical"], ...
        "Location", "best");
    grid on;
    xtickangle(25);

    nexttile;
    bar(labels, tableH1.CalibrationGap);
    hold on;
    errorbar( ...
        1:height(tableH1), ...
        tableH1.CalibrationGap, ...
        tableH1.CalibrationGapCI95, ...
        "k.", "LineWidth", 1);
    yline(0, "--");
    hold off;
    ylabel("Empirical - expected");
    title("Hit-risk calibration gap");
    grid on;
    xtickangle(25);

    saveas(gcf, outputPath);

end
