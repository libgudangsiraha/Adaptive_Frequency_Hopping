function plot_cumulative_communication(resultMap, outputFile)
%PLOT_CUMULATIVE_COMMUNICATION Mean cumulative regret and goodput.
%
% resultMap is a struct array with fields:
%   name
%   multiResults

    figure('Visible', 'off');
    tiledlayout(1, 2);

    nexttile;
    hold on;

    for index = 1:numel(resultMap)
        multiResults = resultMap(index).multiResults;
        numSeeds = numel(multiResults.allMetrics);
        T = numel(multiResults.allMetrics{1}.fixedArmRegret);

        curves = NaN(T, numSeeds);

        for seedIndex = 1:numSeeds
            curves(:, seedIndex) = ...
                multiResults.allMetrics{seedIndex}.fixedArmRegret;
        end

        plot( ...
            mean(curves, 2, 'omitnan'), ...
            'DisplayName', resultMap(index).name);
    end

    xlabel('Round');
    ylabel('Fixed-arm regret');
    title('Cumulative fixed-arm regret');
    grid on;
    legend('Location', 'best');
    hold off;

    nexttile;
    hold on;

    for index = 1:numel(resultMap)
        multiResults = resultMap(index).multiResults;
        numSeeds = numel(multiResults.allMetrics);
        T = numel(multiResults.allMetrics{1}.cumGoodputMbps);

        curves = NaN(T, numSeeds);

        for seedIndex = 1:numSeeds
            curves(:, seedIndex) = ...
                multiResults.allMetrics{seedIndex}.cumGoodputMbps;
        end

        plot( ...
            mean(curves, 2, 'omitnan'), ...
            'DisplayName', resultMap(index).name);
    end

    xlabel('Round');
    ylabel('Cumulative goodput (Mbit-equivalent)');
    title('Cumulative goodput');
    grid on;
    legend('Location', 'best');
    hold off;

    saveas(gcf, outputFile);
    close(gcf);

end
