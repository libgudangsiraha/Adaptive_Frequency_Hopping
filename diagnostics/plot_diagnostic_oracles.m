function plot_diagnostic_oracles(tableD2, outputPath)
%PLOT_DIAGNOSTIC_ORACLES Fixed and dynamic expert-class capacity.

    labels = tableD2.Scenario + "-" + tableD2.ExpertMode;
    categories = categorical(labels, labels, "Ordinal", true);

    values = [ ...
        tableD2.FixedOracleCapture, ...
        tableD2.DynamicExpertCapture];

    figure;
    bar(categories, values);
    ylabel("Dynamic-arm reward capture");
    title("PACT expert-class oracle capacity");
    legend( ...
        ["Best fixed expert", "Per-round best expert"], ...
        "Location", "best");
    ylim([0, 1.05]);
    grid on;
    xtickangle(25);

    saveas(gcf, outputPath);

end
