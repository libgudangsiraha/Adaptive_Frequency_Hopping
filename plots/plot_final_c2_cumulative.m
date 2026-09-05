function plot_final_c2_cumulative(resultMap, outputPath)
%PLOT_FINAL_C2_CUMULATIVE Compact online-performance figure.
%
%   Left:  running-average delivered goodput.
%   Right: running empirical jam-hit probability.

    numMethods = numel(resultMap);

    figure( ...
        "Units", "inches", ...
        "Position", [1, 1, 8.2, 3.25], ...
        "Color", "w");

    layout = tiledlayout(1, 2, ...
        "TileSpacing", "compact", ...
        "Padding", "compact");

    axesHandles = gobjects(2, 1);
    lineHandles = gobjects(numMethods, 1);

    %% ------------------------------------------------------------
    % (a) Running-average goodput
    % -------------------------------------------------------------
    axesHandles(1) = nexttile;
    hold(axesHandles(1), "on");

    for methodIndex = 1:numMethods

        cumulativeCurves = collect_curve( ...
            resultMap(methodIndex).multiResults, ...
            "cumGoodputMbps");

        numRounds = size(cumulativeCurves, 1);
        roundIndex = (1:numRounds).';

        % Convert cumulative delivered goodput into running average.
        runningGoodput = cumulativeCurves ./ roundIndex;

        lineHandles(methodIndex) = plot( ...
            axesHandles(1), ...
            roundIndex, ...
            mean(runningGoodput, 2, "omitnan"), ...
            "LineWidth", 1.25);
    end

    xlabel(axesHandles(1), "Round");
    ylabel(axesHandles(1), "Running-average goodput (Mbps)");
    title(axesHandles(1), "(a) Communication utility");

    grid(axesHandles(1), "on");
    box(axesHandles(1), "on");
    xlim(axesHandles(1), [1, numRounds]);

    hold(axesHandles(1), "off");

    %% ------------------------------------------------------------
    % (b) Running empirical jam-hit
    % -------------------------------------------------------------
    axesHandles(2) = nexttile;
    hold(axesHandles(2), "on");

    for methodIndex = 1:numMethods

        jamHitCurves = collect_curve( ...
            resultMap(methodIndex).multiResults, ...
            "jamHitRate");

        numRounds = size(jamHitCurves, 1);
        roundIndex = (1:numRounds).';

        plot( ...
            axesHandles(2), ...
            roundIndex, ...
            mean(jamHitCurves, 2, "omitnan"), ...
            "LineWidth", 1.25);
    end

    xlabel(axesHandles(2), "Round");
    ylabel(axesHandles(2), "Running empirical jam-hit");
    title(axesHandles(2), "(b) Predictive-jamming exposure");

    grid(axesHandles(2), "on");
    box(axesHandles(2), "on");
    xlim(axesHandles(2), [1, numRounds]);

    hold(axesHandles(2), "off");

    %% Shared legend below both panels
    legendHandle = legend( ...
        axesHandles(1), ...
        lineHandles, ...
        shorten_names(string({resultMap.name})), ...
        "Orientation", "horizontal", ...
        "NumColumns", 3, ...
        "Box", "on");

    legendHandle.Layout.Tile = "south";

    %% Export
    export_pair(gcf, outputPath);

end


function curves = collect_curve(multiResults, fieldName)
%COLLECT_CURVE Collect one time-series metric across all seeds.

    numSeeds = numel(multiResults.allMetrics);

    firstResult = multiResults.allMetrics{1};
    numRounds = numel(firstResult.(char(fieldName)));

    curves = NaN(numRounds, numSeeds);

    for seedIndex = 1:numSeeds
        curves(:, seedIndex) = ...
            multiResults.allMetrics{seedIndex}.(char(fieldName));
    end

end


function output = shorten_names(input)
%SHORTEN_NAMES Convert implementation names into paper labels.

    output = string(input);

    replacements = [
        "LC-Tsallis-INF-Online", "LC-INF"
        "Risk-aware EXP4",       "RA-EXP4"
        "AUFH-EXP3++-1",         "AUFH"
        "D-PACT-AFH-Base",       "D-PACT-Base"
        "D-PACT-AFH",            "D-PACT-Hit"
        "D-PACT-Safe95",         "D-PACT-Safe"
    ];

    for index = 1:size(replacements, 1)
        output(output == replacements(index, 1)) = ...
            replacements(index, 2);
    end

end


function export_pair(fig, outputPath)
%EXPORT_PAIR Export both raster and vector versions.

    [folder, name, ~] = fileparts(outputPath);

    pngPath = fullfile(folder, name + ".png");
    pdfPath = fullfile(folder, name + ".pdf");

    try
        exportgraphics(fig, pngPath, ...
            "Resolution", 300);

        exportgraphics(fig, pdfPath, ...
            "ContentType", "vector");
    catch
        saveas(fig, pngPath);
    end

end