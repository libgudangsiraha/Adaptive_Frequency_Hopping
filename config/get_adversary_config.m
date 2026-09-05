function advCfg = get_adversary_config(adversaryType, baseCfg)
%GET_ADVERSARY_CONFIG Configuration for one adversary model.

    advCfg.type = lower(string(adversaryType));

    % Shared settings
    advCfg.K = baseCfg.K;
    advCfg.M_jam = baseCfg.M_jam;

    switch advCfg.type

        case "none"
            advCfg.name = "No active jammer";
            advCfg.M_jam = 0;

        case "random"
            advCfg.name = "Random jammer";

        case "sweep"
            advCfg.name = "Sweep jammer";
            advCfg.sweep_width = get_optional_field( ...
                baseCfg, "sweep_width", baseCfg.M_jam);

        case "folpetti_ts"
            advCfg.name = "FOLPETTI-inspired TS jammer";
            advCfg.M_jam = 1;
            advCfg.alpha0 = 1.0;
            advCfg.beta0 = 1.0;
            advCfg.mc_samples = get_optional_field( ...
                baseCfg, "folpetti_mc_samples", 2000);
            advCfg.minProbability = 1e-9;

        case "window"
            advCfg.window = 50;
            advCfg.alpha = 1.0;   % Laplace smoothing
            
        case "contextual_online"

            % Arm-wise context features:
            % row 2 = SNR
            % row 3 = delay-good
            % row 4 = availability
            advCfg.featureRows = [2, 3, 4];

            % Online maximum-likelihood update
            advCfg.eta0 = 0.5;
            advCfg.l2 = 1e-4;

            % Softmax temperature
            advCfg.temperature = 0.5;

            % Published q_t always has positive support
            advCfg.uniformFloor = 0.02;

            % Numerical projection
            advCfg.thetaMaxNorm = 10.0;
            
       case "contextual_expert"

            advCfg.name = ...
                "Contextual expert predictor";

            advCfg.K = baseCfg.K;

            %% Arm-wise context features
            % row 2: normalized SNR
            % row 3: delay-good
            % row 4: availability
            advCfg.featureRows = [2, 3, 4];

            %% Context-only experts
            % 15 simplex weight combinations
            advCfg.contextWeightLevel = 4;

            advCfg.contextTemperatures = ...
                [0.05, 0.15, 0.50];

            %% History-only experts
            advCfg.historyWindows = ...
                [20, 100, Inf];

            advCfg.historyTemperatures = ...
                [0.10, 0.30];

            advCfg.historyAlpha = 1.0;

            %% Hybrid experts
            % Columns are canonical context-weight profiles.
            advCfg.hybridContextWeights = [
                1.00, 0.00, 0.00, 0.50, 1/3;
                0.00, 1.00, 0.00, 0.25, 1/3;
                0.00, 0.00, 1.00, 0.25, 1/3
            ];

            advCfg.hybridHistoryWindows = ...
                [20, 100];

            advCfg.hybridMixes = ...
                [0.25, 0.50, 0.75];

            advCfg.hybridTemperatures = ...
                [0.10, 0.30];

            %% Anytime Hedge schedule
            advCfg.etaScale = 1.0;
            advCfg.etaMax = 1.0;

            %% Controlled predictor sharpness
            advCfg.predictionPower = get_optional_field( ...
                baseCfg, "predictor_power", 1.0);

            %% Numerical support only
            advCfg.minProbability = 1e-12;

        otherwise
            error("Unknown adversary type: %s", advCfg.type);
    end

end


function value = get_optional_field(inputStruct, fieldName, defaultValue)

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
