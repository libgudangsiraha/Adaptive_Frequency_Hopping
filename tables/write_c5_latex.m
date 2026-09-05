function write_c5_latex(input, outputPath)
%WRITE_C5_LATEX Write selected C5 result table.

    fileId = fopen(outputPath, "w");

    if fileId < 0
        error("Could not open %s.", outputPath);
    end

    cleanup = onCleanup(@() fclose(fileId));

    fprintf(fileId, "\\begin{tabular}{llrrr}\\n");
    fprintf(fileId, "\\toprule\\n");
    fprintf(fileId, ...
        "Regime & Learner & Goodput & PDR & Jam-hit \\\\\\\\n");
    fprintf(fileId, "\\midrule\\n");

    for index = 1:height(input)

        fprintf(fileId, ...
            "%s & %s & %.3f & %.3f & %.3f \\\\\\n", ...
            latex_escape(short_regime(input.Regime(index))), ...
            latex_escape(short_learner(input.Learner(index))), ...
            input.GoodputMbps(index), ...
            input.PDR(index), ...
            input.EmpiricalJamHit(index));
    end

    fprintf(fileId, "\\bottomrule\\n");
    fprintf(fileId, "\\end{tabular}\\n");

end


function output = short_regime(input)

    output = string(input);

    replacements = [
        "Nonlinear interaction", "Nonlinear QoS"
        "Observable switching", "Observable switching"
        "Exogenous sweep", "Exogenous sweep"
        "Hidden Markov", "Hidden Markov"
    ];

    for index = 1:size(replacements, 1)
        output(output == replacements(index, 1)) = ...
            replacements(index, 2);
    end

end


function output = short_learner(input)

    output = string(input);

    replacements = [
        "LC-Tsallis-INF-Online", "LC-INF"
        "Risk-aware EXP4", "RA-EXP4"
        "AUFH-EXP3++-1", "AUFH"
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
