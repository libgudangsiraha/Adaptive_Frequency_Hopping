function write_model_latex(input, outputPath)
%WRITE_MODEL_LATEX Write concise model-selection LaTeX table.

    fileId = fopen(outputPath, "w");

    if fileId < 0
        error("Could not open %s.", outputPath);
    end

    cleanup = onCleanup(@() fclose(fileId));

    fprintf(fileId, "\\begin{tabular}{lrrrr}\\n");
    fprintf(fileId, "\\toprule\\n");
    fprintf(fileId, ...
        "Regime & Local--LC & Dynamic--LC & Local mass & Recovery \\\\\\\\n");
    fprintf(fileId, "\\midrule\\n");

    for index = 1:height(input)

        regime = latex_escape(short_regime(input.Regime(index)));

        fprintf(fileId, ...
            "%s & %.3f $\\pm$ %.3f & %.3f $\\pm$ %.3f & %.3f & ", ...
            regime, ...
            input.LocalMinusLCGoodputMbps(index), ...
            input.LocalMinusLCGoodputCI95(index), ...
            input.DynamicMinusLCGoodputMbps(index), ...
            input.DynamicMinusLCGoodputCI95(index), ...
            input.DynamicLocalMass(index));

        if isfinite(input.RecoveryPercent(index))
            fprintf(fileId, "%.1f\\%%", input.RecoveryPercent(index));
        else
            fprintf(fileId, "--");
        end

        fprintf(fileId, " \\\\\\n");
    end

    fprintf(fileId, "\\bottomrule\\n");
    fprintf(fileId, "\\end{tabular}\\n");

end


function output = short_regime(input)

    output = string(input);
    output(output == "Nonlinear interaction") = "Nonlinear QoS";
    output(output == "Observable switching") = "Observable switching";

end


function output = latex_escape(input)

    output = char(string(input));
    output = strrep(output, "_", "\\_");
    output = strrep(output, "%", "\\%");

end
