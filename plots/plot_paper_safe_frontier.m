function plot_paper_safe_frontier( ...
    tableS1, tableS2, unconstrained, outputPath)
%PLOT_PAPER_SAFE_FRONTIER Clean final risk-constrained frontier.

    figure( ...
        "Units", "inches", ...
        "Position", [1, 1, 6.8, 4.8]);

    hold on;

    frontier = sortrows( ...
        tableS1(tableS1.IsPareto, :), ...
        "ExpectedJamHit");

    plot( ...
        frontier.EmpiricalJamHit, ...
        frontier.GoodputMbps, ...
        "-o", ...
        "LineWidth", 1.3, ...
        "MarkerSize", 5, ...
        "DisplayName", "D-PACT-Safe frontier");

    scatter( ...
        unconstrained.summary.meanJamHitRate, ...
        unconstrained.summary.meanGoodputMbps, ...
        72, "d", ...
        "LineWidth", 1.3, ...
        "DisplayName", "D-PACT-Hit");

    for index = 1:height(tableS2)

        label = string(tableS2.Label(index));

        switch label
            case "balanced"
                offset = [0.0005, 0.010];
                displayLabel = "Balanced";
            case "strict_safe"
                offset = [0.0005, 0.010];
                displayLabel = "Strict-safe";
            case "safe95"
                offset = [0.0005, 0.010];
                displayLabel = "Safe95";
            otherwise
                offset = [0.0005, 0.010];
                displayLabel = label;
        end

        text( ...
            tableS2.EmpiricalJamHit(index) + offset(1), ...
            tableS2.GoodputMbps(index) + offset(2), ...
            displayLabel, ...
            "FontSize", 9);
    end

    xlabel("Empirical jam-hit rate");
    ylabel("Goodput (Mbps)");
    title("Risk-constrained operating frontier");
    legend("Location", "best");
    grid on;
    box on;
    hold off;

    export_or_save(gcf, outputPath);

end


function export_or_save(fig, outputPath)

    try
        exportgraphics(fig, outputPath, "Resolution", 300);
    catch
        saveas(fig, outputPath);
    end

end
