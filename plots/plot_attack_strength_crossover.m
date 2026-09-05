function plot_attack_strength_crossover(resultTable, outputFile)
%PLOT_ATTACK_STRENGTH_CROSSOVER Goodput under predictor/budget strength.

    data = resultTable(~isfinite(resultTable.JSRdB), :);
    learners = ["LC-Tsallis-INF-Online", "PACT-AFH-Base", "PACT-AFH"];
    powers = unique(data.PredictorPower, 'sorted');
    budgets = unique(data.AttackBudget, 'sorted');

    figure('Visible', 'off', 'Position', [100, 100, 1150, 420]);
    tiledlayout(1, numel(powers), ...
        'TileSpacing', 'compact', 'Padding', 'compact');

    for p = 1:numel(powers)
        nexttile; hold on;
        for l = 1:numel(learners)
            mask = data.PredictorPower == powers(p) ...
                & data.Learner == learners(l);
            subset = sortrows(data(mask, :), 'AttackBudget');
            plot(subset.AttackBudget, subset.GoodputMbps, '-o', ...
                'LineWidth', 1.3, 'DisplayName', learners(l));
        end
        xlabel('Jammed channels per round'); ylabel('Goodput (Mbps)');
        title(sprintf('Predictor power = %.1f', powers(p)));
        grid on; hold off;
    end

    legend('Location', 'southoutside', 'Orientation', 'horizontal');
    saveas(gcf, outputFile); close(gcf);

end
