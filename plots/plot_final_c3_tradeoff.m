function plot_final_c3_tradeoff(tableC3, outputPath)
%PLOT_FINAL_C3_TRADEOFF Attacker-wise goodput-risk scatter panels.

    adversaries = unique(tableC3.Adversary, "stable");
    learners = unique(tableC3.Learner, "stable");

    figure( ...
        "Units", "inches", ...
        "Position", [1, 1, 9.2, 7.0]);

    layout = tiledlayout(2, 2, ...
        "TileSpacing", "compact", ...
        "Padding", "compact");

    legendHandles = gobjects(numel(learners), 1);
    firstAxes = gobjects(1, 1);

    for adversaryIndex = 1:numel(adversaries)

        ax = nexttile;
        if adversaryIndex == 1
            firstAxes = ax;
        end

        hold(ax, "on");

        for learnerIndex = 1:numel(learners)

            mask = tableC3.Adversary == ...
                adversaries(adversaryIndex) ...
                & tableC3.Learner == learners(learnerIndex);

            if any(mask)
                h = scatter( ...
                    ax, ...
                    tableC3.JamHit(mask), ...
                    tableC3.GoodputMbps(mask), ...
                    46, "filled");

                if adversaryIndex == 1
                    legendHandles(learnerIndex) = h;
                end
            end
        end

        xlabel(ax, "Empirical jam-hit");
        ylabel(ax, "Goodput (Mbps)");
        title(ax, shorten_adversary( ...
            adversaries(adversaryIndex)));
        grid(ax, "on");
        box(ax, "on");
        hold(ax, "off");
    end

    legend(firstAxes, legendHandles, ...
        shorten_learner(learners), ...
        "Location", "best");

    title(layout, "Goodput-risk behavior across attackers");

    export_pair(gcf, outputPath);

end


function output = shorten_adversary(input)

    output = string(input);
    output(output == "Contextual-expert white-box") = "White-box";
    output(output == "FOLPETTI-inspired TS") = "FOLPETTI";

end


function output = shorten_learner(input)

    output = string(input);

    replacements = [
        "LC-Tsallis-INF-Online", "LC-INF"
        "Risk-aware EXP4", "RA-EXP4"
        "AUFH-EXP3++-1", "AUFH"
        "D-PACT-AFH-Base", "D-PACT-Base"
        "D-PACT-AFH", "D-PACT-Hit"
        "D-PACT-Safe95", "D-PACT-Safe"
    ];

    for index = 1:size(replacements, 1)
        output(output == replacements(index, 1)) = ...
            replacements(index, 2);
    end

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
