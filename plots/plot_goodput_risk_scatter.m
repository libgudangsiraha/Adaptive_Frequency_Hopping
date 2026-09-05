function plot_goodput_risk_scatter(resultTable, outputFile)
%PLOT_GOODPUT_RISK_SCATTER Honest utility-risk comparison.

    figure('Visible', 'off', 'Position', [100, 100, 1050, 520]);
    tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

    nexttile; hold on;
    scatter(resultTable.Overlap, resultTable.GoodputMbps, 65, 'filled');
    add_labels(resultTable.Overlap, resultTable.GoodputMbps, ...
        resultTable.Learner);
    xlabel('Prediction overlap (lower is better)');
    ylabel('Delivered goodput (Mbps)');
    title('Goodput versus prediction exposure'); grid on; hold off;

    nexttile; hold on;
    scatter(resultTable.JamHit, resultTable.PDR, 65, 'filled');
    add_labels(resultTable.JamHit, resultTable.PDR, resultTable.Learner);
    xlabel('Jammer-hit rate (lower is better)'); ylabel('PDR');
    title('Reliability versus jammer exposure'); grid on; hold off;

    saveas(gcf, outputFile); close(gcf);

end


function add_labels(x, y, labels)

    xRange = max(x) - min(x); yRange = max(y) - min(y);
    if xRange <= 0, xRange = 1; end
    if yRange <= 0, yRange = 1; end

    for index = 1:numel(x)
        dx = 0.012 * xRange;
        dy = 0.012 * yRange * (-1)^index;
        text(x(index) + dx, y(index) + dy, labels(index), ...
            'FontSize', 8, 'Interpreter', 'none');
    end

end
