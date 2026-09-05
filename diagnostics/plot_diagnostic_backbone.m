function plot_diagnostic_backbone(tableD3, outputPath)
%PLOT_DIAGNOSTIC_BACKBONE Online communication and gap decomposition.

    scenarios = unique(tableD3.Adversary, "stable");

    figure;
    tiledlayout(numel(scenarios), 2);

    for scenarioIndex = 1:numel(scenarios)

        mask = tableD3.Adversary == scenarios(scenarioIndex);
        subset = tableD3(mask, :);
        labels = categorical( ...
            subset.Variant, ...
            subset.Variant, ...
            "Ordinal", true);

        nexttile;
        bar(labels, subset.GoodputMbps);
        hold on;
        errorbar( ...
            1:height(subset), ...
            subset.GoodputMbps, ...
            subset.GoodputCI95, ...
            "k.", ...
            "LineWidth", 1);
        hold off;
        ylabel("Goodput (Mbps)");
        title("Online performance: " + scenarios(scenarioIndex));
        grid on;
        xtickangle(30);

        nexttile;
        gapValues = [ ...
            subset.AggregationGap, ...
            subset.RepresentationGap];

        bar(labels, gapValues);
        ylabel("Mean reward gap");
        title("Gap diagnosis: " + scenarios(scenarioIndex));
        legend( ...
            ["Best fixed - actual", ...
             "Dynamic arm - best fixed"], ...
            "Location", "best");
        grid on;
        xtickangle(30);
    end

    saveas(gcf, outputPath);

end
