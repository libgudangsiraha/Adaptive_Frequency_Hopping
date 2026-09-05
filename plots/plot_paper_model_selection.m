function plot_paper_model_selection(tableModel, outputPath)
%PLOT_PAPER_MODEL_SELECTION Final model-selection evidence figure.

    labels = shorten_regime(tableModel.Regime);
    x = 1:height(tableModel);

    figure( ...
        "Units", "inches", ...
        "Position", [1, 1, 7.6, 5.2]);

    layout = tiledlayout(2, 1, ...
        "TileSpacing", "compact", ...
        "Padding", "compact");

    ax1 = nexttile;
    values = [ ...
        tableModel.LocalMinusLCGoodputMbps, ...
        tableModel.DynamicMinusLCGoodputMbps];

    bars = bar(ax1, x, values, "grouped");
    hold(ax1, "on");

    groupWidth = min(0.8, 2 / 3);
    offsets = [-0.5, 0.5] .* groupWidth / 2;

    errorbar(ax1, x + offsets(1), ...
        values(:, 1), ...
        tableModel.LocalMinusLCGoodputCI95, ...
        "k.", "LineWidth", 1.0);

    errorbar(ax1, x + offsets(2), ...
        values(:, 2), ...
        tableModel.DynamicMinusLCGoodputCI95, ...
        "k.", "LineWidth", 1.0);

    yline(ax1, 0, "-");
    ylabel(ax1, "\Delta goodput vs. LC (Mbps)");
    title(ax1, "Online model-class effects");
    xticks(ax1, x);
    xticklabels(ax1, labels);
    grid(ax1, "on");
    box(ax1, "on");
    hold(ax1, "off");

    legend(ax1, bars, ...
        ["Local-only - LC"; "Dynamic - LC"], ...
        "Location", "best");

    ax2 = nexttile;
    bar(ax2, x, tableModel.DynamicLocalMass);
    hold(ax2, "on");

    errorbar(ax2, x, ...
        tableModel.DynamicLocalMass, ...
        tableModel.DynamicLocalMassCI95, ...
        "k.", "LineWidth", 1.0);

    ylim(ax2, [0, 1]);
    ylabel(ax2, "Dynamic Local mass");
    title(ax2, "Master allocation");
    xticks(ax2, x);
    xticklabels(ax2, labels);
    grid(ax2, "on");
    box(ax2, "on");
    hold(ax2, "off");

    title(layout, ...
        "Dynamic adaptation to communication model mismatch");

    export_or_save(gcf, outputPath);

end


function output = shorten_regime(input)

    output = string(input);
    output(output == "Nonlinear interaction") = "Nonlinear QoS";
    output(output == "Observable switching") = "Observable switching";

end


function export_or_save(fig, outputPath)

    try
        exportgraphics(fig, outputPath, "Resolution", 300);
    catch
        saveas(fig, outputPath);
    end

end
