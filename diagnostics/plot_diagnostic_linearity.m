function plot_diagnostic_linearity(tableD1, outputPath)
%PLOT_DIAGNOSTIC_LINEARITY Model fit and arm-selection quality.

    labels = tableD1.Scenario + "-" + tableD1.ModelClass;
    categories = categorical(labels, labels, "Ordinal", true);

    figure;
    tiledlayout(1, 2);

    nexttile;
    bar(categories, tableD1.OracleCapture);
    hold on;
    errorbar( ...
        1:height(tableD1), ...
        tableD1.OracleCapture, ...
        tableD1.OracleCaptureCI95, ...
        "k.", ...
        "LineWidth", 1);
    hold off;
    ylabel("Dynamic-arm reward capture");
    title("Linear versus nonlinear reward models");
    ylim([0, 1.05]);
    grid on;
    xtickangle(25);

    nexttile;
    bar(categories, tableD1.TopArmAccuracy);
    hold on;
    errorbar( ...
        1:height(tableD1), ...
        tableD1.TopArmAccuracy, ...
        tableD1.TopArmAccuracyCI95, ...
        "k.", ...
        "LineWidth", 1);
    hold off;
    ylabel("Top-arm accuracy");
    title("Best-channel ranking accuracy");
    ylim([0, 1.05]);
    grid on;
    xtickangle(25);

    saveas(gcf, outputPath);

end
