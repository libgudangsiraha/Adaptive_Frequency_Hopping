function learner = init_local_linear_base(localCfg)
%INIT_LOCAL_LINEAR_BASE Piecewise local-linear contextual learner.
%
% A separate ridge model is maintained in every joint context cell.
% Unlike the old static partition experts, each cell learns its own
% intercept and coefficient signs online.

    learner.name = "Partitioned Local-Linear";
    learner.K = localCfg.K;
    learner.featureRows = localCfg.featureRows(:)';
    learner.numFeatures = numel(learner.featureRows);
    learner.localBins = localCfg.localBins(:)';
    learner.numCells = prod(learner.localBins);

    learner.ridge = localCfg.ridge;
    learner.temperature = localCfg.temperature;
    learner.minTemperature = localCfg.minTemperature;
    learner.temperatureDecay = localCfg.temperatureDecay;
    learner.ucbScale = localCfg.ucbScale;
    learner.forgetting = localCfg.forgetting;
    learner.offPolicyRatioCap = localCfg.offPolicyRatioCap;

    learner.parameterDim = 1 + learner.numFeatures;
    learner.gramData = zeros( ...
        learner.parameterDim, learner.parameterDim, learner.numCells);
    learner.targetData = zeros( ...
        learner.parameterDim, learner.numCells);
    learner.lastCellUpdate = zeros(learner.numCells, 1);

    learner.lastPolicy = ones(learner.K, 1) / learner.K;
    learner.lastPredictedLoss = zeros(learner.K, 1);
    learner.lastUncertainty = zeros(learner.K, 1);
    learner.maxOffPolicyRatio = 0;
    learner.numUpdates = 0;

end
