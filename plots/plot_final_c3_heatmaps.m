function plot_final_c3_heatmaps(tableC3, outputPath)
%PLOT_FINAL_C3_HEATMAPS Final cross-attacker heatmaps.

    learners = unique(tableC3.Learner, "stable");
    adversaries = unique(tableC3.Adversary, "stable");

    goodput = build_matrix( ...
        tableC3, learners, adversaries, "GoodputMbps");

    jamHit = build_matrix( ...
        tableC3, learners, adversaries, "JamHit");

    figure( ...
        "Units", "inches", ...
        "Position", [1, 1, 10.0, 5.2]);

    layout = tiledlayout(1, 2, ...
        "TileSpacing", "compact", ...
        "Padding", "compact");

    ax1 = nexttile;
    imagesc(ax1, goodput);
    colorbar(ax1);
    title(ax1, "Goodput (Mbps)");
    set_labels(ax1, learners, adversaries);

    ax2 = nexttile;
    imagesc(ax2, jamHit);
    colorbar(ax2);
    title(ax2, "Empirical jam-hit");
    set_labels(ax2, learners, adversaries);

    title(layout, "Cross-attacker robustness");

    export_pair(gcf, outputPath);

end


function matrix = build_matrix( ...
    input, learners, adversaries, fieldName)

    matrix = NaN(numel(learners), numel(adversaries));

    for learnerIndex = 1:numel(learners)
        for adversaryIndex = 1:numel(adversaries)

            mask = input.Learner == learners(learnerIndex) ...
                & input.Adversary == adversaries(adversaryIndex);

            if any(mask)
                matrix(learnerIndex, adversaryIndex) = ...
                    input.(char(fieldName))(mask);
            end
        end
    end

end


function set_labels(ax, learners, adversaries)

    xticks(ax, 1:numel(adversaries));
    xticklabels(ax, shorten_adversary(adversaries));
    yticks(ax, 1:numel(learners));
    yticklabels(ax, shorten_learner(learners));
    xtickangle(ax, 20);
    xlabel(ax, "Attacker");
    ylabel(ax, "Learner");

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
