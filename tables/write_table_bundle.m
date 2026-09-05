function write_table_bundle(inputTable, outputStem)
%WRITE_TABLE_BUNDLE Write CSV and a compact LaTeX tabular file.

    outputStem = char(outputStem);
    outputFolder = fileparts(outputStem);

    if ~isempty(outputFolder) && ~isfolder(outputFolder)
        mkdir(outputFolder);
    end

    writetable(inputTable, [outputStem, '.csv']);

    fileId = fopen([outputStem, '.tex'], 'w');

    if fileId < 0
        error("Could not open LaTeX output file.");
    end

    cleanup = onCleanup(@() fclose(fileId));

    variableNames = string(inputTable.Properties.VariableNames);
    numColumns = width(inputTable);

    fprintf(fileId, '\\begin{tabular}{%s}\n', ...
        repmat('l', 1, numColumns));
    fprintf(fileId, '\\toprule\n');

    for column = 1:numColumns
        fprintf(fileId, '%s', latex_escape(variableNames(column)));

        if column < numColumns
            fprintf(fileId, ' & ');
        else
            fprintf(fileId, ' \\\\ \n');
        end
    end

    fprintf(fileId, '\\midrule\n');

    for row = 1:height(inputTable)
        for column = 1:numColumns
            value = inputTable{row, column};
            fprintf(fileId, '%s', format_value(value));

            if column < numColumns
                fprintf(fileId, ' & ');
            else
                fprintf(fileId, ' \\\\ \n');
            end
        end
    end

    fprintf(fileId, '\\bottomrule\n');
    fprintf(fileId, '\\end{tabular}\n');

end


function output = format_value(value)

    if iscell(value)
        value = value{1};
    end

    if isstring(value) || ischar(value) || iscategorical(value)
        output = latex_escape(string(value));
    elseif isnumeric(value) || islogical(value)
        if isempty(value) || ~isfinite(value(1))
            output = '--';
        else
            output = sprintf('%.6g', value(1));
        end
    else
        output = latex_escape(string(value));
    end

end


function output = latex_escape(input)

    output = char(string(input));
    output = strrep(output, '\', '\textbackslash{}');
    output = strrep(output, '_', '\_');
    output = strrep(output, '%', '\%');
    output = strrep(output, '&', '\&');
    output = strrep(output, '#', '\#');

end
