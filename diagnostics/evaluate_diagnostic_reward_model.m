function metrics = evaluate_diagnostic_reward_model( ...
    model, X, y, roundIndex, armIndex, K)
%EVALUATE_DIAGNOSTIC_REWARD_MODEL Prediction and arm-ranking diagnostics.

    Phi = build_diagnostic_basis(X, model.basisType);
    prediction = Phi * model.theta;

    residual = y - prediction;
    metrics.rmse = sqrt(mean(residual .^ 2));

    denominator = sum((y - mean(y)) .^ 2);
    if denominator <= eps
        metrics.r2 = NaN;
    else
        metrics.r2 = 1 - sum(residual .^ 2) / denominator;
    end

    uniqueRounds = unique(roundIndex, "stable");
    numRounds = numel(uniqueRounds);

    selectedReward = zeros(numRounds, 1);
    oracleReward = zeros(numRounds, 1);
    topArmCorrect = false(numRounds, 1);

    for index = 1:numRounds

        roundValue = uniqueRounds(index);
        mask = roundIndex == roundValue;

        roundPrediction = prediction(mask);
        roundReward = y(mask);
        roundArms = armIndex(mask);

        [~, localSelected] = max(roundPrediction);
        selectedArm = roundArms(localSelected);

        selectedReward(index) = roundReward(localSelected);
        oracleReward(index) = max(roundReward);

        bestMask = roundReward >= max(roundReward) - 1e-12;
        topArmCorrect(index) = any(roundArms(bestMask) == selectedArm);
    end

    metrics.topArmAccuracy = mean(topArmCorrect);
    metrics.meanSelectedReward = mean(selectedReward);
    metrics.meanOracleReward = mean(oracleReward);
    metrics.meanRankingRegret = mean(oracleReward - selectedReward);

    oracleTotal = sum(oracleReward);
    if oracleTotal <= eps
        metrics.oracleCapture = NaN;
    else
        metrics.oracleCapture = sum(selectedReward) / oracleTotal;
    end

end
