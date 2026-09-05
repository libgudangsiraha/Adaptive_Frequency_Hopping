function plot_dynamic_c6_runtime(tableC6, outputPath)
%PLOT_DYNAMIC_C6_RUNTIME Runtime scaling.

    learners = unique(tableC6.Learner, "stable");

    figure( ...
        "Units", "inches", ...
        "Position", [1, 1, 8.2, 3.8]);

    layout = tiledlayout(1, 2, ...
        "TileSpacing", "compact", ...
        "Padding", "compact");

    plot_panel(tableC6, learners, ...
        "K", "RuntimePer1000Rounds", ...
        "Number of channels K", ...
        "Runtime / 1000 rounds (s)", ...
        "Per-round runtime scaling with K");

    plot_panel(tableC6, learners, ...
        "T", "RuntimeSeconds", ...
        "Horizon T", ...
        "Runtime (s)", ...
        "Runtime scaling with T");

    legend(layout, ...
        "Location", "southoutside", ...
        "Orientation", "horizontal");

    export_or_save(gcf, outputPath);
end


function plot_panel( ...
    inputTable, learners, scaleType, ...
    valueField, xLabelText, yLabelText, titleText)

    nexttile;
    hold on;

    for index = 1:numel(learners)

        mask = ...
            inputTable.ScaleType == scaleType ...
            & inputTable.Learner == learners(index);

        subset = sortrows( ...
            inputTable(mask, :), "ScaleValue");

        plot( ...
            subset.ScaleValue, ...
            subset.(char(valueField)), ...
            "-o", ...
            "LineWidth", 1.15, ...
            "DisplayName", ...
            shorten_label(learners(index)));
    end

    xlabel(xLabelText);
    ylabel(yLabelText);
    title(titleText);
    grid on;
    box on;
    hold off;
end


function label = shorten_label(label)

    label = string(label);

    replacements = [
        "LC-Tsallis-INF-Online", "LC-INF"
        "Risk-aware EXP4", "RA-EXP4"
        "AUFH-EXP3++-1", "AUFH"
        "D-PACT-AFH-Base", "D-PACT-B"
        "D-PACT-AFH", "D-PACT-Hit"
        "D-PACT-Safe95", "D-PACT-S95"
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
        exportgraphics(fig, outputPath, "Resolution", 300);
    catch
        saveas(fig, outputPath);
    end
end
