function plot_dynamic_c5_heatmaps(tableC5, outputPath)
%PLOT_DYNAMIC_C5_HEATMAPS Regime robustness with cell values.

    learners = unique(tableC5.Learner, "stable");
    regimes = unique(tableC5.Regime, "stable");

    goodput = NaN(numel(learners), numel(regimes));
    jamHit = NaN(numel(learners), numel(regimes));

    for learnerIndex = 1:numel(learners)
        for regimeIndex = 1:numel(regimes)

            mask = ...
                tableC5.Learner == learners(learnerIndex) ...
                & tableC5.Regime == regimes(regimeIndex);

            if any(mask)
                goodput(learnerIndex, regimeIndex) = ...
                    tableC5.GoodputMbps(mask);

                jamHit(learnerIndex, regimeIndex) = ...
                    tableC5.EmpiricalJamHit(mask);
            end
        end
    end

    figure( ...
        "Units", "inches", ...
        "Position", [1, 1, 12.2, 5.2]);

    layout = tiledlayout(1, 2, ...
        "TileSpacing", "compact", ...
        "Padding", "compact");

    nexttile;
    imagesc(goodput);
    colorbar;
    title("Goodput (Mbps)");
    format_axes(learners, regimes);
    add_cell_text(goodput, "%.2f");

    nexttile;
    imagesc(jamHit);
    colorbar;
    title("Empirical jam-hit");
    format_axes(learners, regimes);
    add_cell_text(jamHit, "%.3f");

    title(layout, "C5 environment and model-mismatch robustness");

    export_or_save(gcf, outputPath);
end


function format_axes(learners, regimes)

    xticks(1:numel(regimes));
    xticklabels(shorten_regime(regimes));
    xtickangle(28);

    yticks(1:numel(learners));
    yticklabels(shorten_learner(learners));

    xlabel("Regime");
    ylabel("Learner");
end


function add_cell_text(values, formatString)

    for row = 1:size(values, 1)
        for column = 1:size(values, 2)

            value = values(row, column);

            if isfinite(value)
                text(column, row, ...
                    sprintf(formatString, value), ...
                    "HorizontalAlignment", "center", ...
                    "FontSize", 7);
            end
        end
    end
end


function output = shorten_learner(input)

    output = string(input);

    replacements = [
        "LC-Tsallis-INF-Online", "LC-INF"
        "Risk-aware EXP4", "RA-EXP4"
        "AUFH-EXP3++-1", "AUFH"
        "D-PACT-AFH-Base", "D-PACT-B"
        "D-PACT-AFH", "D-PACT-Hit"
        "D-PACT-Safe95", "D-PACT-S95"
    ];

    for index = 1:size(replacements, 1)
        output(output == replacements(index, 1)) = ...
            replacements(index, 2);
    end
end


function output = shorten_regime(input)

    output = string(input);

    replacements = [
        "Nonlinear interaction", "Nonlinear"
        "Observable switching", "Obs. switch"
        "Exogenous sweep", "Exog. sweep"
        "Hidden Markov", "Hidden"
    ];

    for index = 1:size(replacements, 1)
        output(output == replacements(index, 1)) = ...
            replacements(index, 2);
    end
end


function export_or_save(fig, outputPath)

    try
        exportgraphics(fig, outputPath, "Resolution", 300);
    catch
        saveas(fig, outputPath);
    end
end
