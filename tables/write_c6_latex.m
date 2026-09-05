function write_c6_latex(input, outputPath)
%WRITE_C6_LATEX Write selected scaling rows.

    fileId = fopen(outputPath, "w");

    if fileId < 0
        error("Could not open %s.", outputPath);
    end

    cleanup = onCleanup(@() fclose(fileId));

    fprintf(fileId, "\\begin{tabular}{llrrrr}\\n");
    fprintf(fileId, "\\toprule\\n");
    fprintf(fileId, ...
        "Scale & Learner & Value & Goodput & Jam-hit & Runtime \\\\\\\\n");
    fprintf(fileId, "\\midrule\\n");

    for index = 1:height(input)

        fprintf(fileId, ...
            "%s & %s & %.0f & %.3f & %.3f & %.2f \\\\\\n", ...
            latex_escape(input.ScaleType(index)), ...
            latex_escape(short_learner(input.Learner(index))), ...
            input.ScaleValue(index), ...
            input.GoodputMbps(index), ...
            input.EmpiricalJamHit(index), ...
            input.RuntimeSeconds(index));
    end

    fprintf(fileId, "\\bottomrule\\n");
    fprintf(fileId, "\\end{tabular}\\n");

end


function output = short_learner(input)

    output = string(input);

    replacements = [
        "LC-Tsallis-INF-Online", "LC-INF"
        "Risk-aware EXP4", "RA-EXP4"
        "D-PACT-AFH", "D-PACT-Hit"
        "D-PACT-Safe95", "D-PACT-Safe"
    ];

    for index = 1:size(replacements, 1)
        output(output == replacements(index, 1)) = ...
            replacements(index, 2);
    end

end


function output = latex_escape(input)

    output = char(string(input));
    output = strrep(output, "_", "\\_");
    output = strrep(output, "%", "\\%");

end
