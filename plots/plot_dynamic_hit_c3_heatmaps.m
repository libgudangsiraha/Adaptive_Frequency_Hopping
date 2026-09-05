function plot_dynamic_hit_c3_heatmaps(tableC3, outputPath)
%PLOT_DYNAMIC_HIT_C3_HEATMAPS Goodput and empirical hit across attackers.

    learners = unique(tableC3.Learner, "stable");
    adversaries = unique(tableC3.Adversary, "stable");

    goodput = NaN(numel(learners), numel(adversaries));
    jamHit = NaN(numel(learners), numel(adversaries));

    for learnerIndex = 1:numel(learners)
        for adversaryIndex = 1:numel(adversaries)

            mask = ...
                tableC3.Learner == learners(learnerIndex) ...
                & tableC3.Adversary == adversaries(adversaryIndex);

            if any(mask)
                goodput(learnerIndex, adversaryIndex) = ...
                    tableC3.GoodputMbps(mask);

                jamHit(learnerIndex, adversaryIndex) = ...
                    tableC3.EmpiricalJamHit(mask);
            end
        end
    end

    figure;
    tiledlayout(1, 2);

    nexttile;
    imagesc(goodput);
    colorbar;
    title("Goodput robustness (Mbps)");
    xticks(1:numel(adversaries));
    xticklabels(adversaries);
    yticks(1:numel(learners));
    yticklabels(learners);
    xtickangle(25);
    xlabel("Attacker");
    ylabel("Learner");

    nexttile;
    imagesc(jamHit);
    colorbar;
    title("Empirical jam-hit robustness");
    xticks(1:numel(adversaries));
    xticklabels(adversaries);
    yticks(1:numel(learners));
    yticklabels(learners);
    xtickangle(25);
    xlabel("Attacker");
    ylabel("Learner");

    saveas(gcf, outputPath);

end
