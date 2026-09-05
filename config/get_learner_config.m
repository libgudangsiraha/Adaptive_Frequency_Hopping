function learnerCfg = get_learner_config(learnerType, baseCfg)
%GET_LEARNER_CONFIG Configuration for one communication learner.
%
% B+C type map:
%   bc_nodetect       - no prediction-aware mechanism
%   bc_loss_only      - NEW dual-channel current-round q-loss
%   bc_explore_only   - q-tilt exploration only
%   bc_detect         - NEW q-loss + q-tilt
%   bc_old_loss_only  - legacy normalized delayed q-loss
%   bc_old_detect     - legacy q-loss + q-tilt
%   bc_scale_control  - legacy loss-scale diagnostic only

    learnerCfg.type = lower(string(learnerType));
    learnerCfg.K = baseCfg.K;

    switch learnerCfg.type

        case "exp3"
            learnerCfg.gamma = 0.20;

        case "aufh_exp3pp"
            learnerCfg.name = ...
                "AUFH-EXP3++-1 (single-channel adaptation)";

            learnerCfg.eta_scale = 0.5;
            learnerCfg.gap_exploration_c = 18.0;
            learnerCfg.gap_floor = 1e-3;
            learnerCfg.max_total_exploration = 0.5;

        case "ucb"
            learnerCfg.ucb_c = 2.0;

        case "ts"
            learnerCfg.ts_alpha0 = 1.0;
            learnerCfg.ts_beta0 = 1.0;
            learnerCfg.ts_mc_samples = 200;

        case "exp4p"
            learnerCfg.exp4p_delta = 0.05;
            learnerCfg.expertCfg = ...
                get_policy_expert_config(baseCfg);
            learnerCfg.T = baseCfg.T;

        case { ...
                "bc_nodetect", ...
                "bc_loss_only", ...
                "bc_explore_only", ...
                "bc_detect", ...
                "bc_old_loss_only", ...
                "bc_old_detect", ...
                "bc_scale_control"}

            %% Human-readable version name
            switch learnerCfg.type
                case "bc_nodetect"
                    learnerCfg.name = ...
                        "PACT-AFH-Base";

                case "bc_loss_only"
                    learnerCfg.name = ...
                        "PACT-AFH-L";

                case "bc_explore_only"
                    learnerCfg.name = ...
                        "PACT-AFH-T";

                case "bc_detect"
                    learnerCfg.name = ...
                        "PACT-AFH";

                case "bc_old_loss_only"
                    learnerCfg.name = ...
                        "PACT-AFH legacy q-loss";

                case "bc_old_detect"
                    learnerCfg.name = ...
                        "PACT-AFH legacy full";

                case "bc_scale_control"
                    learnerCfg.name = ...
                        "PACT-AFH scale control";
            end

            %% Hybrid continuous-linear + partition expert bank
            learnerCfg.expertCfg = ...
                get_pact_expert_config(baseCfg);

            %% Tsallis-FTRL expert aggregation
            % Optional override is used by the diagnostic suite only.
            learnerCfg.eta_scale = get_optional_field( ...
                baseCfg, "pact_eta_scale", 1.0);

            %% Shared contextual exploration schedule
            learnerCfg.gamma_scale = ...
                baseCfg.explore_scale;

            learnerCfg.gamma_max = ...
                baseCfg.explore_gamma_max;

            learnerCfg.explore_uniform_floor = ...
                baseCfg.explore_uniform_floor;

            %% Legacy normalized q-loss parameter
            learnerCfg.detect_lambda = ...
                get_optional_field(baseCfg, "detect_lambda", 0.5);

            %% New dual-channel q-loss parameter
            %
            % This is independent of the communication-loss learning rate.
            % A beta scan should be performed before choosing the final value.
            learnerCfg.detect_beta = ...
                get_optional_field(baseCfg, "detect_beta", 1.0);

            %% Weight of the currently published q_t risk in round t
            %
            % 1.0 implements:
            %   Q_{t-1} + g_t.
            learnerCfg.current_risk_weight = ...
                get_optional_field( ...
                    baseCfg, ...
                    "current_risk_weight", ...
                    1.0);

            %% q-tilt parameters
            learnerCfg.detect_nu = ...
                baseCfg.explore_nu;

            learnerCfg.explore_epsilon = ...
                baseCfg.explore_epsilon;

            %% Prediction-loss mode
            switch learnerCfg.type
                case {"bc_loss_only", "bc_detect"}
                    learnerCfg.predictionLossMode = ...
                        "dual_current";

                case {"bc_old_loss_only", "bc_old_detect"}
                    learnerCfg.predictionLossMode = ...
                        "legacy_normalized";

                case "bc_scale_control"
                    learnerCfg.predictionLossMode = ...
                        "scale_control";

                otherwise
                    learnerCfg.predictionLossMode = "none";
            end

            %% Explicit switches retained for diagnostics/compatibility
            learnerCfg.useNewPredictionLoss = ...
                learnerCfg.predictionLossMode ...
                == "dual_current";

            learnerCfg.useLegacyPredictionLoss = ...
                learnerCfg.predictionLossMode ...
                == "legacy_normalized";

            learnerCfg.usePredictionLoss = ...
                learnerCfg.useNewPredictionLoss ...
                || learnerCfg.useLegacyPredictionLoss;

            learnerCfg.scaleCommunicationLoss = ...
                learnerCfg.predictionLossMode ...
                == "scale_control";

            learnerCfg.usePredictionExploration = ismember( ...
                learnerCfg.type, ...
                ["bc_explore_only", ...
                 "bc_detect", ...
                 "bc_old_detect"]);

        case { ...
                "dpact_nodetect", ...
                "dpact_loss_only", ...
                "dpact_explore_only", ...
                "dpact_detect", ...
                "dpact_safe"}

            switch learnerCfg.type
                case "dpact_nodetect"
                    learnerCfg.name = "D-PACT-AFH-Base";
                case "dpact_loss_only"
                    learnerCfg.name = "D-PACT-AFH-L";
                case "dpact_explore_only"
                    learnerCfg.name = "D-PACT-AFH-T";
                case "dpact_detect"
                    learnerCfg.name = "D-PACT-AFH";
                case "dpact_safe"
                    learnerCfg.name = "D-PACT-Safe";
            end

            learnerCfg.numBaseLearners = 2;
            learnerCfg.baseNames = [ ...
                "LC-Tsallis-INF-Online", ...
                "Partitioned Local-Linear"];

            learnerCfg.lcBaseCfg = ...
                get_learner_config("lc_inf_online", baseCfg);

            learnerCfg.lcBaseCfg.off_policy_ratio_cap = ...
                get_optional_field( ...
                    baseCfg, "dynamic_offpolicy_ratio_cap", 20.0);

            learnerCfg.localCfg.K = baseCfg.K;
            learnerCfg.localCfg.featureRows = get_optional_value( ...
                baseCfg, "local_linear_feature_rows", [2, 3, 4]);
            learnerCfg.localCfg.localBins = get_optional_value( ...
                baseCfg, "local_linear_bins", [4, 4, 2]);
            learnerCfg.localCfg.ridge = get_optional_field( ...
                baseCfg, "local_linear_ridge", 0.10);
            learnerCfg.localCfg.temperature = get_optional_field( ...
                baseCfg, "local_linear_temperature", 0.15);
            learnerCfg.localCfg.minTemperature = get_optional_field( ...
                baseCfg, "local_linear_min_temperature", 0.04);
            learnerCfg.localCfg.temperatureDecay = get_optional_field( ...
                baseCfg, "local_linear_temperature_decay", 0.10);
            learnerCfg.localCfg.ucbScale = get_optional_field( ...
                baseCfg, "local_linear_ucb_scale", 0.15);
            learnerCfg.localCfg.forgetting = get_optional_field( ...
                baseCfg, "local_linear_forgetting", 0.9995);
            learnerCfg.localCfg.offPolicyRatioCap = get_optional_field( ...
                baseCfg, "dynamic_offpolicy_ratio_cap", 20.0);

            learnerCfg.masterEtaScale = get_optional_field( ...
                baseCfg, "dynamic_master_eta_scale", 1.0);
            learnerCfg.gammaScale = get_optional_field( ...
                baseCfg, "dynamic_master_gamma_scale", 0.25);
            learnerCfg.gammaMax = get_optional_field( ...
                baseCfg, "dynamic_master_gamma_max", 0.10);
            learnerCfg.exploreUniformFloor = get_optional_field( ...
                baseCfg, "dynamic_master_uniform_floor", 0.02);
            learnerCfg.lcAnchorScale = get_optional_field( ...
                baseCfg, "dynamic_lc_anchor_scale", 0.50);
            learnerCfg.lcAnchorFloor = get_optional_field( ...
                baseCfg, "dynamic_lc_anchor_floor", 0.0);
            learnerCfg.localPriorPenalty = get_optional_field( ...
                baseCfg, "dynamic_local_prior_penalty", 1.0);
            learnerCfg.forceBase = lower(string(get_optional_value( ...
                baseCfg, "dynamic_force_base", "none")));

            learnerCfg.detectBeta = get_optional_field( ...
                baseCfg, "detect_beta", 8.0);
            learnerCfg.currentRiskWeight = get_optional_field( ...
                baseCfg, "current_risk_weight", 1.0);
            learnerCfg.detectNu = get_optional_field( ...
                baseCfg, "explore_nu", 1.0);
            learnerCfg.exploreEpsilon = get_optional_field( ...
                baseCfg, "explore_epsilon", 1e-3);

            learnerCfg.predictionRiskMode = lower(string( ...
                get_optional_value( ...
                    baseCfg, ...
                    "dynamic_prediction_risk_mode", ...
                    "q_overlap")));

            if ~ismember( ...
                    learnerCfg.predictionRiskMode, ...
                    ["q_overlap", "hit_probability"])
                error( ...
                    "Unknown dynamic_prediction_risk_mode: %s", ...
                    learnerCfg.predictionRiskMode);
            end

            learnerCfg.MJam = min(max( ...
                round(baseCfg.M_jam), 0), baseCfg.K);

            learnerCfg.useNewPredictionLoss = ismember( ...
                learnerCfg.type, ...
                ["dpact_loss_only", "dpact_detect", "dpact_safe"]);

            learnerCfg.usePredictionExploration = ismember( ...
                learnerCfg.type, ...
                ["dpact_explore_only", "dpact_detect"]);

            learnerCfg.useRiskProjection = ...
                learnerCfg.type == "dpact_safe";

            learnerCfg.riskProjectionBudget = get_optional_field( ...
                baseCfg, "dynamic_safe_tau", 0.12);

            learnerCfg.riskProjectionTolerance = get_optional_field( ...
                baseCfg, "dynamic_safe_projection_tolerance", 1e-10);

            learnerCfg.riskProjectionMaxIterations = round( ...
                get_optional_field( ...
                    baseCfg, ...
                    "dynamic_safe_projection_max_iterations", ...
                    80));

            if learnerCfg.useRiskProjection ...
                    && learnerCfg.predictionRiskMode ...
                    ~= "hit_probability"

                error([ ...
                    "D-PACT-Safe requires " ...
                    "dynamic_prediction_risk_mode='hit_probability'."]);
            end

        case {"lc_inf", "lc_inf_pool", "lc_inf_online"}

            if learnerCfg.type == "lc_inf_online"
                learnerCfg.name = "LC-Tsallis-INF-Online";
                learnerCfg.covarianceMode = "online";
            else
                learnerCfg.name = "LC-Tsallis-INF-Pool";
                learnerCfg.covarianceMode = "pool";
            end

            learnerCfg.featureDim = baseCfg.contextDim;
            learnerCfg.eta_scale = 1.0;
            learnerCfg.gamma_scale = 0.25;
            learnerCfg.gamma_max = 0.25;
            learnerCfg.context_pool_size = get_optional_field( ...
                baseCfg, "lc_context_pool_size", 200);
            learnerCfg.online_buffer_size = get_optional_field( ...
                baseCfg, "lc_online_buffer_size", 200);
            learnerCfg.sigma_ridge = 1e-4;
            learnerCfg.sigma_update_period = get_optional_field( ...
                baseCfg, "lc_sigma_update_period", 5);

            if isfield(baseCfg, "contextPool")
                learnerCfg.contextPool = baseCfg.contextPool;
            else
                learnerCfg.contextPool = [];
            end

        case "risk_exp4"
            learnerCfg.exp4p_delta = 0.05;

            learnerCfg.expertCfg = ...
                get_policy_expert_config(baseCfg);

            learnerCfg.T = baseCfg.T;

            learnerCfg.detect_lambda = ...
                baseCfg.detect_lambda;

        otherwise
            error("Unknown learner type: %s", learnerCfg.type);
    end

end


function value = get_optional_field(inputStruct, fieldName, defaultValue)
%GET_OPTIONAL_FIELD Read a scalar optional configuration field.

    fieldName = char(fieldName);

    if isfield(inputStruct, fieldName)
        value = inputStruct.(fieldName);
    else
        value = defaultValue;
    end

    if ~isscalar(value) || ~isfinite(value)
        error( ...
            "Configuration field '%s' must be a finite scalar.", ...
            fieldName);
    end

end

function value = get_optional_value(inputStruct, fieldName, defaultValue)
%GET_OPTIONAL_VALUE Read an optional scalar, string, or vector field.

    fieldName = char(fieldName);

    if isfield(inputStruct, fieldName)
        value = inputStruct.(fieldName);
    else
        value = defaultValue;
    end

end
