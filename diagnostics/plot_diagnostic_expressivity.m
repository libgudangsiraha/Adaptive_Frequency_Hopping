function plot_diagnostic_expressivity(tableD4, outputPath)
%PLOT_DIAGNOSTIC_EXPRESSIVITY Synthetic nonlinear representability.

    tasks = unique(tableD4.Task, "stable");
    modes = unique(tableD4.ExpertMode, "stable");

    fixedCapture = NaN(numel(tasks), numel(modes));
    dynamicCapture = NaN(numel(tasks), numel(modes));

    for taskIndex = 1:numel(tasks)
        for modeIndex = 1:numel(modes)

            mask = ...
                tableD4.Task == tasks(taskIndex) ...
                & tableD4.ExpertMode == modes(modeIndex);

            fixedCapture(taskIndex, modeIndex) = ...
                tableD4.FixedOracleCapture(mask);

            dynamicCapture(taskIndex, modeIndex) = ...
                tableD4.DynamicExpertCapture(mask);
        end
    end

    figure;
    tiledlayout(1, 2);

    nexttile;
    bar(categorical(tasks, tasks), fixedCapture);
    ylabel("Dynamic-arm reward capture");
    title("Best fixed expert");
    legend(modes, "Location", "best");
    ylim([0, 1.05]);
    grid on;
    xtickangle(25);

    nexttile;
    bar(categorical(tasks, tasks), dynamicCapture);
    ylabel("Dynamic-arm reward capture");
    title("Per-round best expert");
    legend(modes, "Location", "best");
    ylim([0, 1.05]);
    grid on;
    xtickangle(25);

    saveas(gcf, outputPath);

end
