function adversary = init_adversary(advCfg)
%INIT_ADVERSARY Initialize adversary state.

    adversary.type = advCfg.type;
    adversary.K = advCfg.K;
    adversary.M_jam = advCfg.M_jam;

    switch adversary.type

        case "none"
            adversary.name = advCfg.name;
            adversary.M_jam = 0;
            adversary.numUpdates = 0;

        case "random"
            adversary.name = advCfg.name;
            adversary.numUpdates = 0;

        case "sweep"
            adversary.name = advCfg.name;
            adversary.sweepWidth = max(1, min( ...
                adversary.K, round(advCfg.sweep_width)));
            adversary.numUpdates = 0;

        case "folpetti_ts"
            adversary.name = advCfg.name;
            adversary.M_jam = 1;

            adversary.alpha = ...
                advCfg.alpha0 * ones(adversary.K, 1);

            adversary.beta = ...
                advCfg.beta0 * ones(adversary.K, 1);

            adversary.mcSamples = advCfg.mc_samples;
            adversary.minProbability = advCfg.minProbability;

            adversary.attackCount = zeros(adversary.K, 1);
            adversary.successCount = zeros(adversary.K, 1);
            adversary.cumulativeAttackSuccess = 0;
            adversary.lastAttackAction = NaN;
            adversary.numUpdates = 0;

        case "window"
            adversary.window = advCfg.window;
            adversary.alpha = advCfg.alpha;
            
        case "contextual_online"

            adversary.featureRows = ...
                advCfg.featureRows;

            adversary.numFeatures = ...
                numel(advCfg.featureRows);

            adversary.eta0 = advCfg.eta0;
            adversary.l2 = advCfg.l2;

            adversary.temperature = ...
                advCfg.temperature;

            adversary.uniformFloor = ...
                advCfg.uniformFloor;

            adversary.thetaMaxNorm = ...
                advCfg.thetaMaxNorm;

            %% Shared arm-quality parameter
            adversary.theta = ...
                zeros(adversary.numFeatures, 1);

            %% Diagnostics
            adversary.numUpdates = 0;
            adversary.cumulativeLogLoss = 0;
            adversary.lastLogLoss = NaN;
            adversary.maxThetaNorm = 0;
            
      case "contextual_expert"

            adversary.name = advCfg.name;
            adversary.K = advCfg.K;

            adversary.expertBank = ...
                build_contextual_predictor_experts(advCfg);

            adversary.numExperts = ...
                adversary.expertBank.numExperts;

            %% Anytime Hedge parameters
            adversary.etaScale = advCfg.etaScale;
            adversary.etaMax = advCfg.etaMax;

            adversary.minProbability = ...
                advCfg.minProbability;
            adversary.predictionPower = ...
                advCfg.predictionPower;

            %% Cumulative full-information expert gain
            adversary.cumExpertGain = ...
                zeros(adversary.numExperts, 1);

            %% Diagnostics
            adversary.lastExpertProb = ...
                ones(adversary.numExperts, 1) ...
                / adversary.numExperts;

            adversary.lastEta = NaN;

            adversary.cumulativeMixtureGain = 0;
            adversary.cumulativeLogLoss = 0;

            adversary.predictorRegret = 0;
            adversary.bestExpertIndex = 1;

            adversary.maxExpertWeight = ...
                1 / adversary.numExperts;

            adversary.numUpdates = 0;

        otherwise
            error("Unknown adversary type: %s", adversary.type);
    end

end