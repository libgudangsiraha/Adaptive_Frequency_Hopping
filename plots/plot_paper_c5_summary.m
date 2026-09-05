function plot_paper_c5_summary(tableC5, outputPath)
%PLOT_PAPER_C5_SUMMARY Final communication robustness summary.

    modelRegimes = [ ...
        "Nominal"; ...
        "Nonlinear interaction"; ...
        "Observable switching"];

    attackRegimes = [ ...
        "White-box"; ...
        "Contaminated"; ...
        "Exogenous sweep"; ...
        "Mixed"; ...
        "Hidden Markov"];

    dynamicLearners = [ ...
        "LC-Tsallis-INF-Online"; ...
        "D-PACT-AFH"; ...
        "D-PACT-Safe95"];

    attackLearners = [ ...
        "LC-Tsallis-INF-Online"; ...
        "Risk-aware EXP4"; ...
        "AUFH-EXP3++-1"; ...
        "D-PACT-AFH"; ...
        "D-PACT-Safe95"];

    figure( ...
        "Units", "inches", ...
        "Position", [1, 1, 10.0, 7.0]);

    layout = tiledlayout(2, 2, ...
        "TileSpacing", "compact", ...
        "Padding", "compact");

    ax1 = nexttile;
    plot_grouped_metric( ...
        ax1, tableC5, modelRegimes, dynamicLearners, ...
        "GoodputMbps", "Goodput (Mbps)", ...
        "Communication-model regimes");

    ax2 = nexttile;
    plot_grouped_metric( ...
        ax2, tableC5, modelRegimes, dynamicLearners, ...
        "MasterLocalMass", "Mean Local-base mass", ...
        "Dynamic model allocation");
    ylim(ax2, [0, 1]);

    ax3 = nexttile;
    handles = plot_grouped_metric( ...
        ax3, tableC5, attackRegimes, attackLearners, ...
        "GoodputMbps", "Goodput (Mbps)", ...
        "Attacked-regime goodput");

    ax4 = nexttile;
    plot_grouped_metric( ...
        ax4, tableC5, attackRegimes, attackLearners, ...
        "EmpiricalJamHit", "Empirical jam-hit", ...
        "Attacked-regime exposure");

    legend(ax3, handles, ...
        shorten_learner(attackLearners), ...
        "Location", "southoutside", ...
        "Orientation", "horizontal");

    title(layout, ...
        "D-PACT communication robustness and risk control");

    export_or_save(gcf, outputPath);

end


function handles = plot_grouped_metric( ...
    ax, input, regimes, learners, ...
    fieldName, yLabelText, titleText)

    values = NaN(numel(regimes), numel(learners));

    for regimeIndex = 1:numel(regimes)
        for learnerIndex = 1:numel(learners)

            mask = input.Regime == regimes(regimeIndex) ...
                & input.Learner == learners(learnerIndex);

            if any(mask)
                values(regimeIndex, learnerIndex) = ...
                    input.(char(fieldName))(mask);
            end
        end
    end

    handles = bar(ax, values, "grouped");

    ylabel(ax, yLabelText);
    title(ax, titleText);
    xticks(ax, 1:numel(regimes));
    xticklabels(ax, shorten_regime(regimes));
    xtickangle(ax, 22);
    grid(ax, "on");
    box(ax, "on");

end


function output = shorten_learner(input)

    output = string(input);

    replacements = [
        "LC-Tsallis-INF-Online", "LC-INF"
        "Risk-aware EXP4", "RA-EXP4"
        "AUFH-EXP3++-1", "AUFH"
        "D-PACT-AFH", "D-PACT-Hit"
        "D-PACT-Safe95", "D-PACT-Safe"
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
