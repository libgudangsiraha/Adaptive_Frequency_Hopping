function plot_communication_pareto(pactTable, baselineTable, outputFile)
%PLOT_COMMUNICATION_PARETO Clean goodput-overlap operating-point plot.

    figure('Visible', 'off', 'Position', [100, 100, 950, 650]);
    hold on;

    scatter(pactTable.Overlap, pactTable.GoodputMbps, ...
        55, 'filled', 'DisplayName', 'PACT-AFH operating points');
    scatter(baselineTable.Overlap, baselineTable.GoodputMbps, ...
        75, 'd', 'LineWidth', 1.3, ...
        'DisplayName', 'Reference baselines');

    for index = 1:height(pactTable)
        if pactTable.Beta(index) == 0 && pactTable.Nu(index) == 0
            label = 'Base';
        elseif pactTable.Beta(index) == 8 && pactTable.Nu(index) == 1
            label = 'Default';
        else
            continue;
        end
        text(pactTable.Overlap(index), pactTable.GoodputMbps(index), ...
            "  " + label, 'FontSize', 9);
    end

    for index = 1:height(baselineTable)
        text(baselineTable.Overlap(index), ...
            baselineTable.GoodputMbps(index), ...
            "  " + baselineTable.Learner(index), ...
            'FontSize', 9, 'Interpreter', 'none');
    end

    xlabel('Mean prediction overlap (lower is better)');
    ylabel('Mean delivered goodput (Mbps)');
    title('Goodput-overlap operating points');
    grid on; legend('Location', 'southoutside', ...
        'Orientation', 'horizontal'); hold off;
    saveas(gcf, outputFile); close(gcf);

end
