function plot_dynamic_communication(tableV1, outputPath)
%PLOT_DYNAMIC_COMMUNICATION Communication and risk comparison.

    adversaries = unique(tableV1.Adversary, "stable");

    figure;
    tiledlayout(numel(adversaries), 2);

    for index = 1:numel(adversaries)
        mask = tableV1.Adversary == adversaries(index);
        subset = tableV1(mask, :);
        labels = categorical( ...
            subset.Variant, subset.Variant, "Ordinal", true);

        nexttile;
        bar(labels, subset.GoodputMbps);
        hold on;
        errorbar(1:height(subset), subset.GoodputMbps, ...
            subset.GoodputCI95, "k.", "LineWidth", 1);
        hold off;
        ylabel("Goodput (Mbps)");
        title("Communication: " + adversaries(index));
        grid on;
        xtickangle(30);

        nexttile;
        riskValues = [subset.Overlap, subset.JamHit];
        bar(labels, riskValues);
        ylabel("Risk rate");
        title("Prediction exposure: " + adversaries(index));
        legend(["Overlap", "Jam hit"], "Location", "best");
        grid on;
        xtickangle(30);
    end

    saveas(gcf, outputPath);

end
