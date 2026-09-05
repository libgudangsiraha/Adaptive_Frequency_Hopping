function plot_final_c4_ablation(tableC4, outputPath)
%PLOT_FINAL_C4_ABLATION Final mechanism and base-model ablation.

    x = 1:height(tableC4);
    labels = shorten_variant(tableC4.Variant);

    figure( ...
        "Units", "inches", ...
        "Position", [1, 1, 9.0, 6.6]);

    layout = tiledlayout(2, 2, ...
        "TileSpacing", "compact", ...
        "Padding", "compact");

    ax1 = nexttile;
    bar(ax1, x, tableC4.GoodputMbps);
    hold(ax1, "on");
    errorbar(ax1, x, ...
        tableC4.GoodputMbps, ...
        tableC4.GoodputCI95, ...
        "k.", "LineWidth", 1.0);
    ylabel(ax1, "Goodput (Mbps)");
    title(ax1, "Communication utility");
    format_axes(ax1, x, labels);
    hold(ax1, "off");

    ax2 = nexttile;
    bar(ax2, x, tableC4.JamHit);
    hold(ax2, "on");
    errorbar(ax2, x, ...
        tableC4.JamHit, ...
        tableC4.JamHitCI95, ...
        "k.", "LineWidth", 1.0);
    ylabel(ax2, "Empirical jam-hit");
    title(ax2, "Prediction exposure");
    format_axes(ax2, x, labels);
    hold(ax2, "off");

    ax3 = nexttile;
    bar(ax3, x, tableC4.PDR);
    hold(ax3, "on");
    errorbar(ax3, x, ...
        tableC4.PDR, ...
        tableC4.PDRCI95, ...
        "k.", "LineWidth", 1.0);
    ylabel(ax3, "PDR");
    title(ax3, "Reliability");
    format_axes(ax3, x, labels);
    hold(ax3, "off");

    ax4 = nexttile;
    bar(ax4, x, tableC4.MasterLocalMass);
    hold(ax4, "on");
    errorbar(ax4, x, ...
        tableC4.MasterLocalMass, ...
        tableC4.MasterLocalMassCI95, ...
        "k.", "LineWidth", 1.0);
    ylim(ax4, [0, 1]);
    ylabel(ax4, "Mean Local mass");
    title(ax4, "Dynamic base allocation");
    format_axes(ax4, x, labels);
    hold(ax4, "off");

    title(layout, ...
        "D-PACT model and risk-mechanism ablation");

    export_pair(gcf, outputPath);

end


function format_axes(ax, x, labels)

    xticks(ax, x);
    xticklabels(ax, labels);
    xtickangle(ax, 18);
    grid(ax, "on");
    box(ax, "on");

end


function output = shorten_variant(input)

    output = string(input);
    output(output == "D-PACT Local-only") = "Local-only";
    output(output == "D-PACT LC-only") = "LC-only";
    output(output == "D-PACT-Base") = "Base";
    output(output == "D-PACT-Hit") = "Hit";
    output(output == "D-PACT-Safe95") = "Safe";

end


function export_pair(fig, outputPath)

    [folder, name, ~] = fileparts(outputPath);
    pngPath = fullfile(folder, name + ".png");
    pdfPath = fullfile(folder, name + ".pdf");

    try
        exportgraphics(fig, pngPath, "Resolution", 300);
        exportgraphics(fig, pdfPath, "ContentType", "vector");
    catch
        saveas(fig, pngPath);
    end

end
