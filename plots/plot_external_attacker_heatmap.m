function plot_external_attacker_heatmap(resultTable, outputFile)
%PLOT_EXTERNAL_ATTACKER_HEATMAP Goodput across attackers.

    learners = unique(resultTable.Learner, 'stable');
    attackers = unique(resultTable.Adversary, 'stable');
    matrix = NaN(numel(learners), numel(attackers));

    for i = 1:numel(learners)
        for j = 1:numel(attackers)
            mask = resultTable.Learner == learners(i) ...
                & resultTable.Adversary == attackers(j);
            if any(mask), matrix(i, j) = resultTable.GoodputMbps(mask); end
        end
    end

    figure('Visible', 'off', 'Position', [100, 100, 1050, 650]);
    imagesc(matrix); colorbar;
    xticks(1:numel(attackers)); xticklabels(attackers);
    yticks(1:numel(learners)); yticklabels(learners);
    xtickangle(25);
    xlabel('Attacker'); ylabel('Learner');
    title('Delivered-goodput robustness across attackers (Mbps)');
    saveas(gcf, outputFile); close(gcf);

end
