function plot_jsr_robustness(resultTable, outputFile)
%PLOT_JSR_ROBUSTNESS PDR and delivered goodput versus JSR.

    learners = unique(resultTable.Learner, 'stable');
    figure('Visible', 'off', 'Position', [100, 100, 1050, 480]);
    tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

    nexttile; hold on;
    for index = 1:numel(learners)
        subset = sortrows(resultTable(resultTable.Learner == learners(index), :), 'JSRdB');
        errorbar(subset.JSRdB, subset.PDR, subset.PDRCI95, '-o', ...
            'LineWidth', 1.1, 'DisplayName', learners(index));
    end
    xlabel('JSR (dB)'); ylabel('PDR'); title('PDR versus JSR'); grid on; hold off;

    nexttile; hold on;
    for index = 1:numel(learners)
        subset = sortrows(resultTable(resultTable.Learner == learners(index), :), 'JSRdB');
        errorbar(subset.JSRdB, subset.GoodputMbps, subset.GoodputCI95, '-o', ...
            'LineWidth', 1.1, 'DisplayName', learners(index));
    end
    xlabel('JSR (dB)'); ylabel('Goodput (Mbps)');
    title('Delivered goodput versus JSR'); grid on; hold off;
    legend('Location', 'southoutside', 'Orientation', 'horizontal');

    saveas(gcf, outputFile); close(gcf);

end
