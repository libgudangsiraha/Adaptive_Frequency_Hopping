function write_dynamic_validation_verdict( ...
    outputPath, tableV1, tableV2)
%WRITE_DYNAMIC_VALIDATION_VERDICT Automatic acceptance summary.

    fileId = fopen(outputPath, "w");
    if fileId < 0
        error("Could not create dynamic validation verdict.");
    end
    cleanup = onCleanup(@() fclose(fileId));

    lcNoAttack = lookup_comm(tableV1, ...
        "LC-Tsallis-INF-Online", "none", "GoodputMbps");
    lcOnlyNoAttack = lookup_comm(tableV1, ...
        "D-PACT LC-only", "none", "GoodputMbps");
    dynamicBaseNoAttack = lookup_comm(tableV1, ...
        "D-PACT-AFH-Base", "none", "GoodputMbps");

    lcAttack = lookup_comm(tableV1, ...
        "LC-Tsallis-INF-Online", "contextual_expert", ...
        "GoodputMbps");
    dynamicFullAttack = lookup_comm(tableV1, ...
        "D-PACT-AFH", "contextual_expert", "GoodputMbps");
    lcAttackOverlap = lookup_comm(tableV1, ...
        "LC-Tsallis-INF-Online", "contextual_expert", "Overlap");
    dynamicAttackOverlap = lookup_comm(tableV1, ...
        "D-PACT-AFH", "contextual_expert", "Overlap");

    nonlinearTasks = ["interaction", "xor", "band_pass", "weight_flip"];
    improvement = NaN(numel(nonlinearTasks), 1);

    for index = 1:numel(nonlinearTasks)
        lcCapture = lookup_synthetic(tableV2, nonlinearTasks(index), ...
            "LC-Tsallis-INF-Online");
        dynamicCapture = lookup_synthetic(tableV2, nonlinearTasks(index), ...
            "D-PACT-AFH-Base");
        improvement(index) = dynamicCapture - lcCapture;
    end

    fprintf(fileId, "# Dynamic PACT validation verdict\n\n");
    fprintf(fileId, "## LC embedding check\n\n");
    fprintf(fileId, "- Native LC goodput: **%.4f Mbps**\n", lcNoAttack);
    fprintf(fileId, "- D-PACT LC-only goodput: **%.4f Mbps**\n", ...
        lcOnlyNoAttack);
    fprintf(fileId, "- Relative difference: **%.2f%%**\n\n", ...
        100 * (lcOnlyNoAttack - lcNoAttack) / max(lcNoAttack, eps));

    fprintf(fileId, "## Linear-friendly communication\n\n");
    fprintf(fileId, "- D-PACT Base / LC goodput ratio: **%.4f**\n\n", ...
        dynamicBaseNoAttack / max(lcNoAttack, eps));

    fprintf(fileId, "## Predictive adversary\n\n");
    fprintf(fileId, "- LC goodput: **%.4f Mbps**\n", lcAttack);
    fprintf(fileId, "- D-PACT full goodput: **%.4f Mbps**\n", ...
        dynamicFullAttack);
    fprintf(fileId, "- LC overlap: **%.4f**\n", lcAttackOverlap);
    fprintf(fileId, "- D-PACT overlap: **%.4f**\n\n", ...
        dynamicAttackOverlap);

    fprintf(fileId, "## Controlled nonlinear tasks\n\n");
    for index = 1:numel(nonlinearTasks)
        fprintf(fileId, "- `%s` D-PACT minus LC capture: **%.4f**\n", ...
            nonlinearTasks(index), improvement(index));
    end

    fprintf(fileId, "\n## Frozen acceptance criteria\n\n");
    fprintf(fileId, ...
        "1. LC-only embedding should be within 1%% of native LC.\n");
    fprintf(fileId, ...
        "2. Dynamic Base should retain at least 98%% of LC goodput " ...
        "in the no-jammer linear-friendly environment.\n");
    fprintf(fileId, ...
        "3. Dynamic Base should improve LC on XOR, band-pass, or " ...
        "weight-flip tasks.\n");
    fprintf(fileId, ...
        "4. Under contextual prediction, full D-PACT should reduce " ...
        "overlap materially; goodput crossover is tested later under " ...
        "stronger predictor and attack-budget sweeps.\n\n");

    lcEmbeddingPass = abs(lcOnlyNoAttack - lcNoAttack) ...
        <= 0.01 * max(lcNoAttack, eps);
    linearPass = dynamicBaseNoAttack >= 0.98 * lcNoAttack;
    nonlinearPass = any(improvement >= 0.03);
    riskPass = dynamicAttackOverlap <= 0.90 * lcAttackOverlap;

    fprintf(fileId, "## Automatic status\n\n");
    fprintf(fileId, "- LC embedding: **%s**\n", pass_text(lcEmbeddingPass));
    fprintf(fileId, "- Linear retention: **%s**\n", pass_text(linearPass));
    fprintf(fileId, "- Nonlinear advantage: **%s**\n", ...
        pass_text(nonlinearPass));
    fprintf(fileId, "- Prediction-risk reduction: **%s**\n", ...
        pass_text(riskPass));

end


function value = lookup_comm(tableValue, variant, adversary, fieldName)
    mask = tableValue.Variant == string(variant) ...
        & tableValue.Adversary == string(adversary);
    value = tableValue.(fieldName)(find(mask, 1));
end


function value = lookup_synthetic(tableValue, task, variant)
    mask = tableValue.Task == string(task) ...
        & tableValue.Variant == string(variant);
    value = tableValue.OracleCapture(find(mask, 1));
end


function text = pass_text(flag)
    if flag
        text = "PASS";
    else
        text = "FAIL";
    end
end
