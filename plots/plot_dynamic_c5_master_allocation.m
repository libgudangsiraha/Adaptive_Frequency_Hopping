function plot_dynamic_c5_master_allocation( ...
    tableMaster, outputPath)
%PLOT_DYNAMIC_C5_MASTER_ALLOCATION Dynamic LC/local master allocation.

    regimes = unique(tableMaster.Regime, "stable");
    learners = unique(tableMaster.Learner, "stable");

    localMass = NaN(numel(regimes), numel(learners));
    goodput = NaN(numel(regimes), numel(learners));

    for regimeIndex = 1:numel(regimes)
        for learnerIndex = 1:numel(learners)

            mask = ...
                tableMaster.Regime == regimes(regimeIndex) ...
                & tableMaster.Learner == learners(learnerIndex);

            if any(mask)
                localMass(regimeIndex, learnerIndex) = ...
                    tableMaster.MasterLocalMass(mask);

                goodput(regimeIndex, learnerIndex) = ...
                    tableMaster.GoodputMbps(mask);
            end
        end
    end

    figure( ...
        "Units", "inches", ...
        "Position", [1, 1, 10.2, 6.0]);

    layout = tiledlayout(2, 1, ...
        "TileSpacing", "compact", ...
        "Padding", "compact");

    nexttile;
    bar(localMass);
    ylim([0, 1]);
    ylabel("Mean Local-base mass");
    title("Dynamic master allocation");
    xticks(1:numel(regimes));
    xticklabels(shorten_regime(regimes));
    xtickangle(25);
    grid on;

    nexttile;
    bar(goodput);
    ylabel("Goodput (Mbps)");
    title("Communication performance of dynamic variants");
    xticks(1:numel(regimes));
    xticklabels(shorten_regime(regimes));
    xtickangle(25);
    grid on;

    legend( ...
        shorten_learner(learners), ...
        "Location", "southoutside", ...
        "Orientation", "horizontal");

    title(layout, ...
        "C5 dynamic model selection: LC versus Local");

    export_or_save(gcf, outputPath);
end


function output = shorten_learner(input)

    output = string(input);

    replacements = [
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
