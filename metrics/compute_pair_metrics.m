function metrics = compute_pair_metrics(results, cfg)
%COMPUTE_PAIR_METRICS Metrics for one communication simulation run.

    T = length(results.reward);
    time = (1:T)';

    %% Normalized communication performance
    reward = results.reward(:);
    rate = results.rate(:);

    metrics.cumReward = cumsum(reward);
    metrics.avgReward = metrics.cumReward ./ time;
    metrics.finalAvgReward = metrics.avgReward(end);

    metrics.cumRate = cumsum(rate);
    metrics.avgRate = metrics.cumRate ./ time;
    metrics.finalAvgRate = metrics.avgRate(end);

    %% Physical communication metrics
    pdr = results.pdr(:);
    goodputMbps = results.goodputMbps(:);
    adaptiveGoodputMbps = results.adaptiveGoodputMbps(:);
    cappedGoodputMbps = results.cappedGoodputMbps(:);
    fixedGoodputMbps = results.fixedGoodputMbps(:);
    sinr = results.sinr(:);
    sinrDb = results.sinrDb(:);
    spectralEfficiency = results.spectralEfficiency(:);
    ber = results.ber(:);
    retransmission = results.retransmission(:);
    switching = results.switching(:);

    metrics.cumPdr = cumsum(pdr);
    metrics.avgPdr = metrics.cumPdr ./ time;
    metrics.finalPdr = metrics.avgPdr(end);

    metrics.cumGoodputMbps = cumsum(goodputMbps);
    metrics.avgGoodputMbps = metrics.cumGoodputMbps ./ time;
    metrics.finalAvgGoodputMbps = metrics.avgGoodputMbps(end);

    metrics.avgAdaptiveGoodputMbps = ...
        cumsum(adaptiveGoodputMbps) ./ time;
    metrics.finalAvgAdaptiveGoodputMbps = ...
        metrics.avgAdaptiveGoodputMbps(end);

    metrics.avgCappedGoodputMbps = ...
        cumsum(cappedGoodputMbps) ./ time;
    metrics.finalAvgCappedGoodputMbps = ...
        metrics.avgCappedGoodputMbps(end);

    metrics.avgFixedGoodputMbps = ...
        cumsum(fixedGoodputMbps) ./ time;
    metrics.finalAvgFixedGoodputMbps = ...
        metrics.avgFixedGoodputMbps(end);

    metrics.avgSinrLinear = cumsum(sinr) ./ time;
    metrics.finalMeanSinrLinear = metrics.avgSinrLinear(end);
    metrics.finalMeanSinrDb = ...
        10 * log10(max(metrics.finalMeanSinrLinear, realmin));

    metrics.avgInstantaneousSinrDb = cumsum(sinrDb) ./ time;
    metrics.finalAvgInstantaneousSinrDb = ...
        metrics.avgInstantaneousSinrDb(end);

    metrics.avgSpectralEfficiency = ...
        cumsum(spectralEfficiency) ./ time;

    metrics.finalAvgSpectralEfficiency = ...
        metrics.avgSpectralEfficiency(end);

    metrics.avgBer = cumsum(ber) ./ time;
    metrics.finalAvgBer = metrics.avgBer(end);

    metrics.retransmissionRate = ...
        cumsum(retransmission) ./ time;

    metrics.finalRetransmissionRate = ...
        metrics.retransmissionRate(end);

    metrics.switchingRate = cumsum(switching) ./ time;
    metrics.finalSwitchingRate = metrics.switchingRate(end);

    %% Regret diagnostics from counterfactual arm rewards
    armReward = results.armReward;

    if ~isequal(size(armReward), [cfg.K, T])
        error("armReward has an invalid size.");
    end

    cumulativeArmReward = cumsum(armReward, 2);
    bestFixedCumulativeReward = ...
        max(cumulativeArmReward, [], 1)';

    metrics.fixedArmRegret = ...
        bestFixedCumulativeReward - metrics.cumReward;

    metrics.finalFixedArmRegret = ...
        metrics.fixedArmRegret(end);

    bestInstantReward = max(armReward, [], 1)';

    metrics.dynamicOracleRegret = ...
        cumsum(bestInstantReward - reward);

    metrics.finalDynamicOracleRegret = ...
        metrics.dynamicOracleRegret(end);

    metrics.averageFixedArmRegret = ...
        metrics.finalFixedArmRegret / T;

    %% Detectability
    overlap = results.overlap(:);
    riskAtAction = results.riskAtAction(:);
    predictionHit = results.predictionHit(:);

    metrics.cumOverlap = cumsum(overlap);
    metrics.avgOverlap = metrics.cumOverlap ./ time;
    metrics.finalAvgOverlap = metrics.avgOverlap(end);

    metrics.cumRiskAtAction = cumsum(riskAtAction);
    metrics.avgRiskAtAction = metrics.cumRiskAtAction ./ time;
    metrics.finalAvgRiskAtAction = metrics.avgRiskAtAction(end);

    metrics.cumPredictionHit = cumsum(predictionHit);
    metrics.predictionHitRate = metrics.cumPredictionHit ./ time;
    metrics.finalPredictionHitRate = ...
        metrics.predictionHitRate(end);

    metrics.overlapHitGap = ...
        metrics.finalPredictionHitRate ...
        - metrics.finalAvgOverlap;

    metrics.overlapRiskGap = ...
        metrics.finalAvgRiskAtAction ...
        - metrics.finalAvgOverlap;

    %% Communication failures and calibrated hit risk
    jamHit = results.jamHit(:);
    expectedJamHit = results.expectedJamHit(:);
    hitRiskAtAction = results.hitRiskAtAction(:);
    occHit = results.occHit(:);

    metrics.cumExpectedJamHit = cumsum(expectedJamHit);
    metrics.avgExpectedJamHit = ...
        metrics.cumExpectedJamHit ./ time;
    metrics.finalAvgExpectedJamHit = ...
        metrics.avgExpectedJamHit(end);

    metrics.cumHitRiskAtAction = cumsum(hitRiskAtAction);
    metrics.avgHitRiskAtAction = ...
        metrics.cumHitRiskAtAction ./ time;
    metrics.finalAvgHitRiskAtAction = ...
        metrics.avgHitRiskAtAction(end);

    metrics.cumJamHit = cumsum(jamHit);
    metrics.jamHitRate = metrics.cumJamHit ./ time;
    metrics.finalJamHitRate = metrics.jamHitRate(end);

    metrics.expectedJamHitCalibrationGap = ...
        metrics.jamHitRate - metrics.avgExpectedJamHit;
    metrics.finalExpectedJamHitCalibrationGap = ...
        metrics.expectedJamHitCalibrationGap(end);

    metrics.actionRiskCalibrationGap = ...
        metrics.jamHitRate - metrics.avgHitRiskAtAction;
    metrics.finalActionRiskCalibrationGap = ...
        metrics.actionRiskCalibrationGap(end);

    metrics.cumOccHit = cumsum(occHit);
    metrics.occHitRate = metrics.cumOccHit ./ time;
    metrics.finalOccHitRate = metrics.occHitRate(end);

    %% Risk-projection diagnostics
    if isfield(results, "riskProjectionActive")

        active = double(results.riskProjectionActive(:));
        projectionKl = results.riskProjectionKl(:);
        preProjectionRisk = results.preProjectionHitRisk(:);
        postProjectionRisk = results.postProjectionHitRisk(:);
        violation = results.riskProjectionViolation(:);

        metrics.finalRiskProjectionActivationRate = ...
            mean(active, "omitnan");
        metrics.finalAvgRiskProjectionKl = ...
            mean(projectionKl, "omitnan");
        metrics.finalAvgPreProjectionHitRisk = ...
            mean(preProjectionRisk, "omitnan");
        metrics.finalAvgPostProjectionHitRisk = ...
            mean(postProjectionRisk, "omitnan");
        metrics.finalMaxRiskProjectionViolation = ...
            max(violation, [], "omitnan");

    else

        metrics.finalRiskProjectionActivationRate = NaN;
        metrics.finalAvgRiskProjectionKl = NaN;
        metrics.finalAvgPreProjectionHitRisk = NaN;
        metrics.finalAvgPostProjectionHitRisk = NaN;
        metrics.finalMaxRiskProjectionViolation = NaN;
    end

    %% Legacy scalarized diagnostic
    legacyEffectiveReward = ...
        results.legacyEffectiveReward(:);

    legacyEffectiveLoss = ...
        results.legacyEffectiveLoss(:);

    metrics.cumLegacyEffectiveReward = ...
        cumsum(legacyEffectiveReward);

    metrics.avgLegacyEffectiveReward = ...
        metrics.cumLegacyEffectiveReward ./ time;

    metrics.finalAvgLegacyEffectiveReward = ...
        metrics.avgLegacyEffectiveReward(end);

    metrics.cumLegacyEffectiveLoss = ...
        cumsum(legacyEffectiveLoss);

    metrics.avgLegacyEffectiveLoss = ...
        metrics.cumLegacyEffectiveLoss ./ time;

    metrics.finalAvgLegacyEffectiveLoss = ...
        metrics.avgLegacyEffectiveLoss(end);

    % Backward-compatible aliases.
    metrics.finalAvgEffectiveReward = ...
        metrics.finalAvgLegacyEffectiveReward;

    metrics.finalAvgEffectiveLoss = ...
        metrics.finalAvgLegacyEffectiveLoss;

    %% Moving averages and sample efficiency
    if isfield(cfg, "moving_window")
        W = min(cfg.moving_window, T);
    else
        W = min(50, T);
    end

    metrics.movingReward = movmean(reward, W);
    metrics.movingGoodputMbps = movmean(goodputMbps, W);
    metrics.movingPdr = movmean(pdr, W);
    metrics.movingOverlap = movmean(overlap, W);
    metrics.movingPredictionHit = movmean(predictionHit, W);
    metrics.movingExpectedJamHit = ...
        movmean(expectedJamHit, W);
    metrics.movingJamHit = movmean(jamHit, W);

    tailStart = max(1, T - W + 1);
    finalGoodputTarget = ...
        0.90 * mean(goodputMbps(tailStart:T));

    firstTarget = find( ...
        metrics.movingGoodputMbps >= finalGoodputTarget, ...
        1, "first");

    if isempty(firstTarget)
        metrics.roundsTo90PercentFinalGoodput = NaN;
    else
        metrics.roundsTo90PercentFinalGoodput = firstTarget;
    end

    %% Action distribution and entropy
    actionHistogram = histcounts( ...
        results.action, 1:(cfg.K + 1));

    actionDistribution = actionHistogram(:) / T;

    metrics.actionHistogram = actionHistogram;
    metrics.actionDistribution = actionDistribution;

    validProbability = ...
        actionDistribution(actionDistribution > 0);

    metrics.actionEntropy = ...
        -sum(validProbability .* log(validProbability));

    metrics.normalizedActionEntropy = ...
        metrics.actionEntropy / log(cfg.K);

    %% Identifiers
    metrics.learnerType = results.learnerType;
    metrics.learnerName = results.learnerName;
    metrics.adversaryType = results.adversaryType;
    metrics.environmentRegime = results.environmentRegime;

end
