function learner = init_learner(learnerCfg)
%INIT_LEARNER Initialize communication learner.

    learner.type = learnerCfg.type;
    learner.K = learnerCfg.K;

    switch learner.type

        case "exp3"
            learner.name = "EXP3";
            learner.gamma = learnerCfg.gamma;
            learner.logWeights = zeros(learner.K, 1);

        case "aufh_exp3pp"
            learner.name = learnerCfg.name;

            learner.etaScale = learnerCfg.eta_scale;
            learner.gapExplorationC = ...
                learnerCfg.gap_exploration_c;
            learner.gapFloor = learnerCfg.gap_floor;
            learner.maxTotalExploration = ...
                learnerCfg.max_total_exploration;

            learner.cumLossHat = zeros(learner.K, 1);
            learner.counts = zeros(learner.K, 1);
            learner.lastEta = NaN;
            learner.lastExploration = ...
                ones(learner.K, 1) / learner.K;
            learner.numUpdates = 0;

        case "ucb"
            learner.name = "UCB";
            learner.counts = zeros(learner.K, 1);
            learner.meanReward = zeros(learner.K, 1);
            learner.ucb_c = learnerCfg.ucb_c;

        case "ts"
            learner.name = "Thompson Sampling";

            learner.alpha = ...
                learnerCfg.ts_alpha0 * ones(learner.K, 1);

            learner.beta = ...
                learnerCfg.ts_beta0 * ones(learner.K, 1);

            learner.counts = zeros(learner.K, 1);
            learner.ts_mc_samples = learnerCfg.ts_mc_samples;

        case { ...
                "bc_nodetect", ...
                "bc_loss_only", ...
                "bc_explore_only", ...
                "bc_detect", ...
                "bc_old_loss_only", ...
                "bc_old_detect", ...
                "bc_scale_control"}

            learner.name = learnerCfg.name;

            %% Prediction-aware architecture
            learner.predictionLossMode = ...
                learnerCfg.predictionLossMode;

            learner.usePredictionLoss = ...
                learnerCfg.usePredictionLoss;

            learner.useNewPredictionLoss = ...
                learnerCfg.useNewPredictionLoss;

            learner.useLegacyPredictionLoss = ...
                learnerCfg.useLegacyPredictionLoss;

            learner.scaleCommunicationLoss = ...
                learnerCfg.scaleCommunicationLoss;

            learner.usePredictionExploration = ...
                learnerCfg.usePredictionExploration;

            %% Build hybrid continuous-linear/partition experts
            learner.expertBank = ...
                build_pact_experts(learnerCfg.expertCfg);

            learner.numExperts = ...
                learner.expertBank.numExperts;

            %% Tsallis-FTRL settings
            learner.etaScale = learnerCfg.eta_scale;

            %% Shared exploration settings
            learner.gammaScale = ...
                learnerCfg.gamma_scale;

            learner.gammaMax = ...
                learnerCfg.gamma_max;

            learner.exploreUniformFloor = ...
                learnerCfg.explore_uniform_floor;

            %% Legacy q-loss parameter
            learner.detectLambda = ...
                learnerCfg.detect_lambda;

            %% New dual-channel q-loss parameters
            learner.detectBeta = ...
                learnerCfg.detect_beta;

            learner.currentRiskWeight = ...
                learnerCfg.current_risk_weight;

            %% q-tilt parameters
            learner.detectNu = learnerCfg.detect_nu;

            learner.exploreEpsilon = ...
                learnerCfg.explore_epsilon;

            %% Separate cumulative channels
            %
            % Raw importance-weighted communication loss.
            learner.cumCommExpertLoss = ...
                zeros(learner.numExperts, 1);

            % Normalized prediction-risk signal:
            %   g_t(i) = [d_t(i) - 1/K] / [1 - 1/K].
            learner.cumPredictionExpertRisk = ...
                zeros(learner.numExperts, 1);

            % Legacy normalized mixed objective, retained only for
            % old-q-loss and scale-control ablations.
            learner.cumLegacyExpertLoss = ...
                zeros(learner.numExperts, 1);

            % Backward-compatible alias:
            %   - communication loss for new/no-loss versions;
            %   - legacy objective for legacy/control versions.
            learner.cumExpertLoss = ...
                zeros(learner.numExperts, 1);

            %% Raw expected q-risk diagnostics
            learner.cumulativeExpectedExpertRisk = ...
                zeros(learner.numExperts, 1);

            %% Diagnostics
            learner.lastExpertProb = ...
                ones(learner.numExperts, 1) ...
                / learner.numExperts;

            learner.lastEta = NaN;
            learner.lastGamma = NaN;

            learner.lastCurrentExpertRiskRaw = ...
                zeros(learner.numExperts, 1);

            learner.lastCurrentExpertRiskNormalized = ...
                zeros(learner.numExperts, 1);

            learner.lastEffectiveExpertLoss = ...
                zeros(learner.numExperts, 1);

            learner.maxEstimatedExpertLoss = 0;
            learner.maxEstimatedCommExpertLoss = 0;
            learner.maxLegacyEstimatedExpertLoss = 0;
            learner.maxAbsPredictionRiskSignal = 0;

            learner.numUpdates = 0;

            %% Human-readable ablation label
            switch learner.type
                case "bc_nodetect"
                    learner.ablationLabel = "BC-00";

                case "bc_loss_only"
                    learner.ablationLabel = "BC-new10";

                case "bc_explore_only"
                    learner.ablationLabel = "BC-01";

                case "bc_detect"
                    learner.ablationLabel = "BC-new11";

                case "bc_old_loss_only"
                    learner.ablationLabel = "BC-old10";

                case "bc_old_detect"
                    learner.ablationLabel = "BC-old11";

                case "bc_scale_control"
                    learner.ablationLabel = "BC-scale";
            end

        case { ...
                "dpact_nodetect", ...
                "dpact_loss_only", ...
                "dpact_explore_only", ...
                "dpact_detect", ...
                "dpact_safe"}

            learner.name = learnerCfg.name;
            learner.baseNames = learnerCfg.baseNames;
            learner.numBaseLearners = learnerCfg.numBaseLearners;

            learner.lcBase = init_learner(learnerCfg.lcBaseCfg);
            learner.lcBase.offPolicyRatioCap = ...
                learnerCfg.lcBaseCfg.off_policy_ratio_cap;
            learner.lcBase.maxOffPolicyRatio = 0;

            learner.localBase = ...
                init_local_linear_base(learnerCfg.localCfg);

            learner.masterEtaScale = learnerCfg.masterEtaScale;
            learner.gammaScale = learnerCfg.gammaScale;
            learner.gammaMax = learnerCfg.gammaMax;
            learner.exploreUniformFloor = ...
                learnerCfg.exploreUniformFloor;
            learner.lcAnchorScale = learnerCfg.lcAnchorScale;
            learner.lcAnchorFloor = learnerCfg.lcAnchorFloor;
            learner.forceBase = learnerCfg.forceBase;

            learner.detectBeta = learnerCfg.detectBeta;
            learner.currentRiskWeight = ...
                learnerCfg.currentRiskWeight;
            learner.detectNu = learnerCfg.detectNu;
            learner.exploreEpsilon = learnerCfg.exploreEpsilon;
            learner.predictionRiskMode = ...
                learnerCfg.predictionRiskMode;
            learner.MJam = learnerCfg.MJam;
            learner.useNewPredictionLoss = ...
                learnerCfg.useNewPredictionLoss;
            learner.usePredictionExploration = ...
                learnerCfg.usePredictionExploration;

            learner.useRiskProjection = ...
                learnerCfg.useRiskProjection;
            learner.riskProjectionBudget = ...
                learnerCfg.riskProjectionBudget;
            learner.riskProjectionTolerance = ...
                learnerCfg.riskProjectionTolerance;
            learner.riskProjectionMaxIterations = ...
                learnerCfg.riskProjectionMaxIterations;

            learner.lastRiskProjectionActive = false;
            learner.lastRiskProjectionLambda = 0;
            learner.lastRiskProjectionKl = 0;
            learner.lastPreProjectionRisk = NaN;
            learner.lastPostProjectionRisk = NaN;
            learner.lastRiskProjectionViolation = 0;

            learner.masterCumCommLoss = ...
                [0; learnerCfg.localPriorPenalty];
            learner.masterCumPredictionRisk = ...
                zeros(learner.numBaseLearners, 1);
            learner.cumulativeExpectedBaseRisk = ...
                zeros(learner.numBaseLearners, 1);

            learner.lastMasterProb = ...
                ones(learner.numBaseLearners, 1) ...
                / learner.numBaseLearners;
            learner.lastBasePolicies = ...
                ones(learner.K, learner.numBaseLearners) / learner.K;
            learner.lastEta = NaN;
            learner.lastGamma = NaN;
            learner.lastCurrentBaseRiskRaw = ...
                zeros(learner.numBaseLearners, 1);
            learner.lastCurrentBaseRiskNormalized = ...
                zeros(learner.numBaseLearners, 1);
            learner.lastEffectiveMasterLoss = ...
                zeros(learner.numBaseLearners, 1);
            learner.lastPredictionRiskVector = ...
                zeros(learner.K, 1);
            learner.lastPredictionRiskReference = NaN;
            learner.maxEstimatedMasterLoss = 0;
            learner.maxAbsPredictionRiskSignal = 0;
            learner.numUpdates = 0;

        case "exp4p"
            learner.name = "EXP4.P";

            learner.expertBank = ...
                build_generic_experts(learnerCfg.expertCfg);

            learner.numExperts = ...
                learner.expertBank.numExperts;

            learner.delta = learnerCfg.exp4p_delta;
            learner.T = learnerCfg.T;

            K = learner.K;
            N = learner.numExperts;
            T = learner.T;

            learner.pMin = sqrt(log(N) / (K * T));
            learner.pMin = min(learner.pMin, 1 / K);

            learner.confidenceScale = sqrt( ...
                log(N / learner.delta) / (K * T));

            learner.logWeights = zeros(N, 1);

            learner.cumulativeEstimatedReward = zeros(N, 1);
            learner.cumulativeVarianceProxy = zeros(N, 1);

        case "risk_exp4"
            learner.name = "Risk-aware EXP4";

            learner.expertBank = ...
                build_generic_experts(learnerCfg.expertCfg);

            learner.numExperts = ...
                learner.expertBank.numExperts;

            learner.delta = learnerCfg.exp4p_delta;
            learner.T = learnerCfg.T;

            learner.detectLambda = ...
                learnerCfg.detect_lambda;

            K = learner.K;
            N = learner.numExperts;
            T = learner.T;

            learner.pMin = sqrt(log(N) / (K * T));
            learner.pMin = min(learner.pMin, 1 / K);

            learner.confidenceScale = sqrt( ...
                log(N / learner.delta) / (K * T));

            learner.logWeights = zeros(N, 1);

            learner.cumulativeEstimatedUtility = ...
                zeros(N, 1);

            learner.cumulativeExpectedRisk = ...
                zeros(N, 1);

            learner.cumulativeVarianceProxy = ...
                zeros(N, 1);

        case {"lc_inf", "lc_inf_pool", "lc_inf_online"}
            learner.name = learnerCfg.name;
            learner.featureDim = learnerCfg.featureDim;
            learner.etaScale = learnerCfg.eta_scale;
            learner.gammaScale = learnerCfg.gamma_scale;
            learner.gammaMax = learnerCfg.gamma_max;
            learner.sigmaRidge = learnerCfg.sigma_ridge;
            learner.sigmaUpdatePeriod = learnerCfg.sigma_update_period;
            learner.covarianceMode = learnerCfg.covarianceMode;
            learner.onlineBufferSize = learnerCfg.online_buffer_size;
            learner.contextPool = learnerCfg.contextPool;

            if learner.covarianceMode == "pool" ...
                    && isempty(learner.contextPool)
                error([ ...
                    "LC-Tsallis-INF-Pool requires an independent " ...
                    "context pool in cfg.contextPool."]);
            end

            if learner.covarianceMode == "online"
                learner.contextPool = zeros( ...
                    learner.featureDim, learner.K, 0);
            end

            learner.cumThetaHat = ...
                zeros(learner.featureDim, 1);

            learner.sigmaCache = [];
            learner.sigmaInvCache = [];
            learner.sigmaRcond = NaN;
            learner.lastSigmaUpdate = -Inf;

            learner.lastThetaHat = ...
                zeros(learner.featureDim, 1);

            learner.maxThetaHatNorm = 0;
            learner.numUpdates = 0;

        otherwise
            error("Unknown learner type: %s", learner.type);
    end

end
