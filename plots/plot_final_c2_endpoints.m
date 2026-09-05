function plot_final_c2_endpoints(tableC2, outputPath)
%PLOT_FINAL_C2_ENDPOINTS Final endpoint goodput-risk tradeoff.
%
%   Baselines use hollow markers.
%   D-PACT variants use filled markers.
%   Colors and markers are fixed by method name so that the visual
%   identity remains consistent even if the table order changes.

    figure( ...
        "Units", "inches", ...
        "Position", [1, 1, 7.2, 5.0], ...
        "Color", "w");

    axesHandle = axes;
    hold(axesHandle, "on");

    methodNames = shorten_names(tableC2.Learner);
    handles = gobjects(height(tableC2), 1);

    for index = 1:height(tableC2)

        [methodColor, methodMarker, isFilled] = ...
            style_for_method(methodNames(index));

        if isFilled
            markerFaceColor = methodColor;
            lineWidth = 1.25;
            markerSize = 7.5;
        else
            markerFaceColor = "none";
            lineWidth = 1.10;
            markerSize = 7.0;
        end

        handles(index) = errorbar( ...
            axesHandle, ...
            tableC2.JamHit(index), ...
            tableC2.GoodputMbps(index), ...
            tableC2.GoodputCI95(index), ...
            tableC2.GoodputCI95(index), ...
            tableC2.JamHitCI95(index), ...
            tableC2.JamHitCI95(index), ...
            methodMarker, ...
            "LineStyle", "none", ...
            "Color", methodColor, ...
            "MarkerEdgeColor", methodColor, ...
            "MarkerFaceColor", markerFaceColor, ...
            "LineWidth", lineWidth, ...
            "MarkerSize", markerSize, ...
            "CapSize", 6);
    end

    xlabel(axesHandle, "Empirical jam-hit");
    ylabel(axesHandle, "Goodput (Mbps)");
    title(axesHandle, "Final goodput-risk operating points");

    grid(axesHandle, "on");
    box(axesHandle, "on");

    legend( ...
        axesHandle, ...
        handles, ...
        methodNames, ...
        "Location", "best", ...
        "Box", "on");

    hold(axesHandle, "off");

    export_pair(gcf, outputPath);

end


function [color, marker, isFilled] = style_for_method(methodName)
%STYLE_FOR_METHOD Return the fixed paper style for each method.

    switch string(methodName)

        % ---------------------------------------------------------
        % Baselines: hollow markers
        % ---------------------------------------------------------
        case "UCB"
            color = [0.35, 0.35, 0.35];
            marker = "o";
            isFilled = false;

        case "Thompson Sampling"
            color = [0.85, 0.45, 0.10];
            marker = "s";
            isFilled = false;

        case "EXP3"
            color = [0.93, 0.69, 0.13];
            marker = "^";
            isFilled = false;

        case "LC-INF"
            color = [0.49, 0.18, 0.56];
            marker = "v";
            isFilled = false;

        case "RA-EXP4"
            color = [0.47, 0.67, 0.19];
            marker = ">";
            isFilled = false;

        case "AUFH"
            color = [0.30, 0.75, 0.93];
            marker = "<";
            isFilled = false;

        % ---------------------------------------------------------
        % Proposed methods: filled markers
        % ---------------------------------------------------------
        case "D-PACT-Base"
            color = [0.64, 0.08, 0.18];
            marker = "d";
            isFilled = true;

        case "D-PACT-Hit"
            color = [0.00, 0.35, 0.75];
            marker = "p";
            isFilled = true;

        case "D-PACT-Safe"
            color = [0.80, 0.20, 0.55];
            marker = "h";
            isFilled = true;

        otherwise
            color = [0.20, 0.20, 0.20];
            marker = "o";
            isFilled = false;
    end

end


function output = shorten_names(input)

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