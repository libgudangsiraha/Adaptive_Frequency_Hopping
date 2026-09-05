function plot_dynamic_nonlinear(tableV2, outputPath)
%PLOT_DYNAMIC_NONLINEAR Controlled nonlinear oracle capture.

    tasks = unique(tableV2.Task, "stable");
    variants = unique(tableV2.Variant, "stable");
    values = NaN(numel(tasks), numel(variants));

    for taskIndex = 1:numel(tasks)
        for variantIndex = 1:numel(variants)
            mask = tableV2.Task == tasks(taskIndex) ...
                & tableV2.Variant == variants(variantIndex);
            values(taskIndex, variantIndex) = ...
                tableV2.OracleCapture(mask);
        end
    end

    figure;
    bar(categorical(tasks, tasks), values);
    ylabel("Dynamic-oracle reward capture");
    title("Dynamic learner expressivity");
    legend(variants, "Location", "best");
    ylim([0, 1.05]);
    grid on;
    xtickangle(25);

    saveas(gcf, outputPath);

end
