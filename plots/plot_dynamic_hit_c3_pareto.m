function plot_dynamic_hit_c3_pareto(tableC3, outputPath)
%PLOT_DYNAMIC_HIT_C3_PARETO Per-attacker goodput-risk operating points.

    adversaries = unique(tableC3.Adversary, "stable");

    figure;
    tiledlayout(2, 2);

    for adversaryIndex = 1:numel(adversaries)

        adversary = adversaries(adversaryIndex);
        subset = tableC3(tableC3.Adversary == adversary, :);

        nexttile;
        scatter( ...
            subset.EmpiricalJamHit, ...
            subset.GoodputMbps, ...
            55, "filled");
        hold on;

        for rowIndex = 1:height(subset)
            text( ...
                subset.EmpiricalJamHit(rowIndex), ...
                subset.GoodputMbps(rowIndex), ...
                "  " + subset.Learner(rowIndex), ...
                "FontSize", 7);
        end

        xlabel("Empirical jam-hit");
        ylabel("Goodput (Mbps)");
        title(adversary);
        grid on;
        hold off;
    end

    saveas(gcf, outputPath);

end
