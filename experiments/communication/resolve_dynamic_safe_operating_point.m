function point = resolve_dynamic_safe_operating_point( ...
    projectRoot, label)
%RESOLVE_DYNAMIC_SAFE_OPERATING_POINT Load a saved Safe operating point.
%
% Search order: full -> quick -> smoke. Fallbacks reflect the final
% K=12, M=1 study.

    if nargin < 2
        label = "safe95";
    end

    label = lower(string(label));
    valid = ["balanced", "strict_safe", "safe95"];

    if ~ismember(label, valid)
        error("Unknown Safe operating-point label: %s", label);
    end

    modes = ["full", "quick", "smoke"];

    for mode = modes

        candidate = fullfile( ...
            projectRoot, ...
            "results", ...
            "dynamic_safe_projection", ...
            char(mode), ...
            "tables", ...
            "Table_S2_recommended_safe_points.csv");

        if ~isfile(candidate)
            continue;
        end

        inputTable = readtable(candidate, ...
            "TextType", "string");

        match = lower(strtrim(inputTable.Label)) == label;

        if any(match)
            row = inputTable(find(match, 1, "first"), :);

            point.label = label;
            point.tau = row.Tau;
            point.referenceK = 12;
            point.referenceAttackBudget = 1;
            point.source = string(candidate);
            return;
        end
    end

    fallbackTau.balanced = 0.10;
    fallbackTau.strict_safe = 0.085;
    fallbackTau.safe95 = 0.11;

    point.label = label;
    point.tau = fallbackTau.(char(label));
    point.referenceK = 12;
    point.referenceAttackBudget = 1;
    point.source = "fallback";

    warning( ...
        "Safe operating point '%s' was not found. " ...
        + "Using tau=%.6f.", ...
        label, point.tau);

end
