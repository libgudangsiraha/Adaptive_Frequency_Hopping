function plot_dynamic_safe_cross_attacker(tableS4, outputPath)
%PLOT_DYNAMIC_SAFE_CROSS_ATTACKER Compact C3 overlay.

    adversaries = unique(tableS4.Adversary, "stable");

    figure( ...
        "Units", "inches", ...
        "Position", [1, 1, 8.2, 6.4]);

    layout = tiledlayout(2, 2, ...
        "TileSpacing", "compact", ...
        "Padding", "compact");

    markers = ["o", "s", "^", "d", "v", "p"];

    for adversaryIndex = 1:numel(adversaries)

        adversary = adversaries(adversaryIndex);
        subset = tableS4(tableS4.Adversary == adversary, :);

        nexttile;
        hold on;

        for rowIndex = 1:height(subset)

            markerIndex = 1 + mod(rowIndex - 1, numel(markers));

            scatter( ...
                subset.EmpiricalJamHit(rowIndex), ...
                subset.GoodputMbps(rowIndex), ...
                58, ...
                markers(markerIndex), ...
                "filled", ...
                "DisplayName", ...
                shorten_label(subset.Label(rowIndex)));
        end

        xlabel("Empirical jam-hit");
        ylabel("Goodput (Mbps)");
        title(adversary);
        grid on;
        box on;
        hold off;
    end

    axesHandles = findobj(gcf, "Type", "axes");
    if ~isempty(axesHandles)
        legend(axesHandles(end), ...
            "Location", "best");
    end

    export_or_save(gcf, outputPath);

end


function label = shorten_label(label)

    label = string(label);

    replacements = [
        "LC-Tsallis-INF-Online", "LC-INF"
        "Risk-aware EXP4", "RA-EXP4"
        "AUFH-EXP3++-1", "AUFH"
        "D-PACT-AFH", "D-PACT-Hit"
        "D-PACT-Safe-balanced", "D-PACT-Safe-B"
        "D-PACT-Safe-low_risk", "D-PACT-Safe-L"
    ];

    for index = 1:size(replacements, 1)
        if label == replacements(index, 1)
            label = replacements(index, 2);
            return;
        end
    end

end


function export_or_save(fig, outputPath)

    try
        exportgraphics(fig, outputPath, ...
            "Resolution", 300);
    catch
        saveas(fig, outputPath);
    end

end
