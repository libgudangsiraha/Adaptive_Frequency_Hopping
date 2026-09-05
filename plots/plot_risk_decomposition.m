function plot_risk_decomposition(resultTable, outputFile)
%PLOT_RISK_DECOMPOSITION PACT mechanism risk components.

    values = [resultTable.BaseRisk, ...
        resultTable.ExplorationRisk, resultTable.Overlap];
    figure('Visible', 'off', 'Position', [100, 100, 950, 600]);
    bar(categorical(resultTable.Learner, resultTable.Learner), values);
    ylabel('Prediction risk');
    title('PACT-AFH mechanism risk decomposition');
    legend({'Base-policy risk', 'Exploration risk', 'Total overlap'}, ...
        'Location', 'southoutside', 'Orientation', 'horizontal');
    grid on; saveas(gcf, outputFile); close(gcf);

end
