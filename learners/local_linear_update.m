function learner = local_linear_update( ...
    learner, feedback, aux, t)
%LOCAL_LINEAR_UPDATE Off-policy update of one local ridge model.

    a_t = feedback.action;
    observedLoss = 1 - min(max(feedback.reward, 0), 1);

    masterPolicy = feedback.pi(:);
    basePolicy = aux.policy(:);

    denominator = max(masterPolicy(a_t), 1e-12);
    ratio = basePolicy(a_t) / denominator;
    ratio = min(max(ratio, 0), learner.offPolicyRatioCap);

    cellId = aux.cellIndex(a_t);
    phi = aux.phiMatrix(:, a_t);

    lastUpdate = learner.lastCellUpdate(cellId);

    if lastUpdate <= 0
        decay = 1;
    else
        decay = learner.forgetting ^ max(t - lastUpdate, 0);
    end

    learner.gramData(:, :, cellId) = ...
        decay .* learner.gramData(:, :, cellId) ...
        + ratio .* (phi * phi');

    learner.targetData(:, cellId) = ...
        decay .* learner.targetData(:, cellId) ...
        + ratio .* phi .* observedLoss;

    learner.lastCellUpdate(cellId) = t;
    learner.lastPolicy = basePolicy;
    learner.lastPredictedLoss = aux.predictedLoss;
    learner.lastUncertainty = aux.uncertainty;
    learner.maxOffPolicyRatio = max( ...
        learner.maxOffPolicyRatio, ratio);
    learner.numUpdates = learner.numUpdates + 1;

end
