function plot_cumulative_communication_v2(resultMap, outputFile)
%PLOT_CUMULATIVE_COMMUNICATION_V2 Utility, reliability and exposure curves.

    figure('Visible', 'off', 'Position', [100, 100, 1200, 780]);
    tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

    fields = ["cumGoodputMbps", "avgPdr", "jamHitRate", "avgOverlap"];
    titles = ["Cumulative delivered goodput", "Running PDR", ...
        "Running jammer-hit rate", "Running prediction overlap"];
    ylabels = ["Mbit-equivalent", "PDR", "Jam-hit rate", "Overlap"];

    for tileIndex = 1:4
        nexttile; hold on;
        for index = 1:numel(resultMap)
            multiResults = resultMap(index).multiResults;
            curves = collect_curve(multiResults, fields(tileIndex));
            plot(mean(curves, 2, 'omitnan'), ...
                'LineWidth', 1.3, 'DisplayName', resultMap(index).name);
        end
        xlabel('Round'); ylabel(ylabels(tileIndex));
        title(titles(tileIndex)); grid on; hold off;
    end

    legend('Location', 'southoutside', 'Orientation', 'horizontal');
    saveas(gcf, outputFile); close(gcf);

end


function curves = collect_curve(multiResults, fieldName)

    numSeeds = numel(multiResults.allMetrics);
    first = multiResults.allMetrics{1};
    T = numel(first.(fieldName));
    curves = NaN(T, numSeeds);
    for seedIndex = 1:numSeeds
        curves(:, seedIndex) = ...
            multiResults.allMetrics{seedIndex}.(fieldName);
    end

end
