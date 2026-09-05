function plot_dynamic_model_class_probe(tableM, outputPath)
%PLOT_DYNAMIC_MODEL_CLASS_PROBE Focused nonlinear model-class comparison.

    regimes = unique(tableM.Regime, "stable");
    variants = unique(tableM.Variant, "stable");

    goodput = NaN(numel(regimes), numel(variants));
    localMass = NaN(numel(regimes), numel(variants));

    for regimeIndex = 1:numel(regimes)
        for variantIndex = 1:numel(variants)

            mask = ...
                tableM.Regime == regimes(regimeIndex) ...
                & tableM.Variant == variants(variantIndex);

            if any(mask)
                goodput(regimeIndex, variantIndex) = ...
                    tableM.GoodputMbps(mask);

                localMass(regimeIndex, variantIndex) = ...
                    tableM.MasterLocalMass(mask);
            end
        end
    end

    figure( ...
        "Units", "inches", ...
        "Position", [1, 1, 8.2, 5.6]);

    layout = tiledlayout(2, 1, ...
        "TileSpacing", "compact", ...
        "Padding", "compact");

    nexttile;
    bar(goodput);
    ylabel("Goodput (Mbps)");
    title("Observable nonlinear model-class performance");
    xticks(1:numel(regimes));
    xticklabels(["Nonlinear"; "Observable switching"]);
    grid on;

    nexttile;
    bar(localMass);
    ylim([0, 1]);
    ylabel("Mean Local-base mass");
    title("Dynamic master response");
    xticks(1:numel(regimes));
    xticklabels(["Nonlinear"; "Observable switching"]);
    grid on;

    legend( ...
        variants, ...
        "Location", "southoutside", ...
        "Orientation", "horizontal");

    title(layout, ...
        "LC versus Local model-class diagnostic");

    export_or_save(gcf, outputPath);
end


function export_or_save(fig, outputPath)

    try
        exportgraphics(fig, outputPath, "Resolution", 300);
    catch
        saveas(fig, outputPath);
    end
end
