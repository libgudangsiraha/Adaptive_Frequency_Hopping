function write_hit_risk_verdict( ...
    outputPath, tableH1, tableH2, cfg)
%WRITE_HIT_RISK_VERDICT Summarize the four-way rerun.

    fileId = fopen(outputPath, "w");

    if fileId < 0
        error("Could not create hit-risk verdict.");
    end

    cleanup = onCleanup(@() fclose(fileId));

    base = get_row(tableH1, "D-PACT-AFH-Base");
    qFull = get_row(tableH1, "D-PACT-AFH q-overlap");
    hitFull = get_row(tableH1, "D-PACT-AFH hit-risk");

    fprintf(fileId, "# Hit-risk alignment verdict\n\n");
    fprintf(fileId, "- K: %d\n", cfg.K);
    fprintf(fileId, "- M_jam: %d\n", cfg.M_jam);
    fprintf(fileId, "- Uniform hit reference M/K: %.6f\n\n", ...
        cfg.M_jam / cfg.K);

    fprintf(fileId, "## Main operating points\n\n");
    fprintf(fileId, ...
        "| Variant | Goodput | Overlap | Expected hit | Empirical hit | Calibration gap |\n");
    fprintf(fileId, ...
        "|---|---:|---:|---:|---:|---:|\n");

    write_row(fileId, base);
    write_row(fileId, qFull);
    write_row(fileId, hitFull);

    fprintf(fileId, "\n## Acceptance checks\n\n");

    goodputRetention = ...
        hitFull.GoodputMbps / max(base.GoodputMbps, eps);

    expectedReduction = ...
        base.ExpectedJamHit - hitFull.ExpectedJamHit;

    empiricalReduction = ...
        base.EmpiricalJamHit - hitFull.EmpiricalJamHit;

    calibrationTolerance = ...
        max(0.01, 2 * hitFull.CalibrationGapCI95);

    calibrationPass = ...
        abs(hitFull.CalibrationGap) <= calibrationTolerance;
    expectedPass = expectedReduction > 0;
    empiricalPass = empiricalReduction > 0;
    goodputPass = goodputRetention >= 0.98;

    fprintf(fileId, ...
        "- Expected jam-hit reduction versus Base: **%.6f** (%s)\n", ...
        expectedReduction, pass_text(expectedPass));
    fprintf(fileId, ...
        "- Empirical jam-hit reduction versus Base: **%.6f** (%s)\n", ...
        empiricalReduction, pass_text(empiricalPass));
    fprintf(fileId, ...
        "- Goodput retention versus Base: **%.4f** (%s)\n", ...
        goodputRetention, pass_text(goodputPass));
    fprintf(fileId, ...
        "- Hit-risk calibration gap: **%.6f** (%s)\n", ...
        hitFull.CalibrationGap, pass_text(calibrationPass));

    fprintf(fileId, "\n## Paired effects\n\n");
    fprintf(fileId, ...
        "See `Table_H2_paired_effects.csv` for paired confidence intervals.\n\n");

    if expectedPass && empiricalPass ...
            && goodputPass && calibrationPass
        fprintf(fileId, ...
            "**Verdict:** the exact hit-risk formulation passes the " ...
            "targeted rerun and can replace q-overlap as the primary " ...
            "prediction-risk channel.\n");
    else
        fprintf(fileId, ...
            "**Verdict:** at least one target is not yet satisfied. " ...
            "Do not run the complete communication suite yet; inspect " ...
            "the paired effects before changing beta or nu.\n");
    end

end


function row = get_row(inputTable, name)

    mask = inputTable.Variant == string(name);

    if sum(mask) ~= 1
        error("Could not identify variant: %s", name);
    end

    row = inputTable(mask, :);

end


function write_row(fileId, row)

    fprintf(fileId, ...
        "| %s | %.6f | %.6f | %.6f | %.6f | %.6f |\n", ...
        row.Variant, ...
        row.GoodputMbps, ...
        row.Overlap, ...
        row.ExpectedJamHit, ...
        row.EmpiricalJamHit, ...
        row.CalibrationGap);

end


function textValue = pass_text(value)

    if value
        textValue = "PASS";
    else
        textValue = "FAIL";
    end

end
