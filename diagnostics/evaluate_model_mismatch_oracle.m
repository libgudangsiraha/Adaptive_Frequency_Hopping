function result = evaluate_model_mismatch_oracle(cfg)
%EVALUATE_MODEL_MISMATCH_ORACLE Fast global-versus-local class test.
%
% Uses all-arm outcomes and a held-out time split. This is not an online
% bandit result. It is a fail-fast representational-capacity diagnostic:
% before spending minutes or hours on online experiments, verify that
% the Local class has measurable held-out headroom over one global
% linear model.

    env = generate_environment(cfg);

    K = cfg.K;
    T = cfg.T;

    reward = zeros(K, T);
    goodput = zeros(K, T);
    noJam = false(K, 1);

    for t = 1:T
        outcomes = compute_all_arm_outcomes( ...
            env.H(:, t), ...
            env.occupied(:, t), ...
            env.noisePower(:, t), ...
            noJam, ...
            cfg);

        reward(:, t) = outcomes.reward;
        goodput(:, t) = outcomes.goodputMbps;
    end

    trainFraction = get_optional_scalar( ...
        cfg, "model_mismatch_train_fraction", 0.60);

    trainFraction = min(max(trainFraction, 0.20), 0.80);

    permutation = randperm(T);
    numTrain = max(1, min(T - 1, ...
        floor(trainFraction * T)));

    trainTimes = permutation(1:numTrain);
    testTimes = permutation((numTrain + 1):end);

    featureRows = get_optional_vector( ...
        cfg, "local_linear_feature_rows", [2, 3, 4]);

    bins = get_optional_vector( ...
        cfg, "local_linear_bins", [4, 4, 2]);

    ridge = get_optional_scalar( ...
        cfg, "model_mismatch_oracle_ridge", 0.05);

    trainFeatures = reshape( ...
        env.context(featureRows, :, trainTimes), ...
        numel(featureRows), []);

    trainReward = reshape( ...
        reward(:, trainTimes), 1, []);

    globalTheta = fit_ridge( ...
        trainFeatures, trainReward, ridge);

    [localTheta, localHasData] = fit_local_ridge( ...
        trainFeatures, trainReward, bins, ridge, globalTheta);

    globalSelectedReward = zeros(numel(testTimes), 1);
    localSelectedReward = zeros(numel(testTimes), 1);
    oracleReward = zeros(numel(testTimes), 1);

    globalSelectedGoodput = zeros(numel(testTimes), 1);
    localSelectedGoodput = zeros(numel(testTimes), 1);
    oracleGoodput = zeros(numel(testTimes), 1);

    globalTopAccuracy = zeros(numel(testTimes), 1);
    localTopAccuracy = zeros(numel(testTimes), 1);

    for index = 1:numel(testTimes)

        t = testTimes(index);
        features = env.context(featureRows, :, t);

        globalPrediction = predict_global( ...
            features, globalTheta);

        localPrediction = predict_local( ...
            features, localTheta, localHasData, ...
            bins, globalTheta);

        [~, globalArm] = max(globalPrediction);
        [~, localArm] = max(localPrediction);
        [oracleReward(index), oracleArm] = max(reward(:, t));

        globalSelectedReward(index) = reward(globalArm, t);
        localSelectedReward(index) = reward(localArm, t);

        globalSelectedGoodput(index) = goodput(globalArm, t);
        localSelectedGoodput(index) = goodput(localArm, t);
        oracleGoodput(index) = max(goodput(:, t));

        globalTopAccuracy(index) = double(globalArm == oracleArm);
        localTopAccuracy(index) = double(localArm == oracleArm);
    end

    result.regime = string(cfg.environment_regime);
    result.globalReward = mean(globalSelectedReward);
    result.localReward = mean(localSelectedReward);
    result.oracleReward = mean(oracleReward);

    result.globalCapture = ...
        sum(globalSelectedReward) / max(sum(oracleReward), eps);

    result.localCapture = ...
        sum(localSelectedReward) / max(sum(oracleReward), eps);

    result.captureGain = ...
        result.localCapture - result.globalCapture;

    result.globalGoodputMbps = mean(globalSelectedGoodput);
    result.localGoodputMbps = mean(localSelectedGoodput);
    result.oracleGoodputMbps = mean(oracleGoodput);

    result.goodputGainMbps = ...
        result.localGoodputMbps ...
        - result.globalGoodputMbps;

    result.globalTopAccuracy = mean(globalTopAccuracy);
    result.localTopAccuracy = mean(localTopAccuracy);

    minimumGain = get_optional_scalar( ...
        cfg, "model_mismatch_min_capture_gain", 0.005);

    result.minimumCaptureGain = minimumGain;
    result.pass = result.captureGain >= minimumGain;
    result.numTrainTimes = numel(trainTimes);
    result.numTestTimes = numel(testTimes);

end


function theta = fit_ridge(features, target, ridge)

    phi = [ones(1, size(features, 2)); features];
    dimension = size(phi, 1);

    theta = ...
        (phi * phi' + ridge * eye(dimension)) ...
        \ (phi * target(:));

end


function [theta, hasData] = fit_local_ridge( ...
    features, target, bins, ridge, globalTheta)

    numFeatures = size(features, 1);
    parameterDim = 1 + numFeatures;
    numCells = prod(bins);

    theta = repmat(globalTheta, 1, numCells);
    hasData = false(numCells, 1);

    cellIndex = local_cell_indices(features, bins);
    minimumSamples = max(2 * parameterDim, 8);

    for cellId = 1:numCells

        mask = cellIndex == cellId;

        if nnz(mask) < minimumSamples
            continue;
        end

        theta(:, cellId) = fit_ridge( ...
            features(:, mask), ...
            target(mask), ...
            ridge);

        hasData(cellId) = true;
    end

end


function prediction = predict_global(features, theta)

    phi = [ones(1, size(features, 2)); features];
    prediction = theta' * phi;
    prediction = min(max(prediction(:), 0), 1);

end


function prediction = predict_local( ...
    features, theta, hasData, bins, globalTheta)

    K = size(features, 2);
    prediction = zeros(K, 1);

    cellIndex = local_cell_indices(features, bins);

    for arm = 1:K

        cellId = cellIndex(arm);

        if hasData(cellId)
            armTheta = theta(:, cellId);
        else
            armTheta = globalTheta;
        end

        phi = [1; features(:, arm)];
        prediction(arm) = armTheta' * phi;
    end

    prediction = min(max(prediction, 0), 1);

end


function cellIndex = local_cell_indices(features, bins)

    numSamples = size(features, 2);
    numDimensions = size(features, 1);

    if numDimensions ~= numel(bins)
        error("Local-bin dimension does not match features.");
    end

    subscript = ones(numDimensions, numSamples);

    for dimension = 1:numDimensions

        value = min(max(features(dimension, :), 0), 1);

        subscript(dimension, :) = min( ...
            floor(value .* bins(dimension)) + 1, ...
            bins(dimension));
    end

    multiplier = [1, cumprod(bins(1:end-1))]';
    cellIndex = 1 + sum( ...
        (subscript - 1) .* multiplier, 1);

end


function value = get_optional_scalar(inputStruct, fieldName, defaultValue)

    fieldName = char(fieldName);

    if isfield(inputStruct, fieldName)
        value = inputStruct.(fieldName);
    else
        value = defaultValue;
    end

    if ~isscalar(value) || ~isfinite(value)
        error("Configuration field '%s' must be finite.", fieldName);
    end

end


function value = get_optional_vector(inputStruct, fieldName, defaultValue)

    fieldName = char(fieldName);

    if isfield(inputStruct, fieldName)
        value = inputStruct.(fieldName);
    else
        value = defaultValue;
    end

    value = value(:)';

end
