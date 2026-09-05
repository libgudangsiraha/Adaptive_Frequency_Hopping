function env = generate_environment(cfg)
%GENERATE_ENVIRONMENT Generate the wireless environment.
%
% Supported cfg.environment_regime values:
%   stochastic
%   contaminated_stochastic
%   oblivious_sweep
%   adaptive_adversarial
%   mixed
%   hidden_markov
%   nonlinear_interaction
%   observable_switching
%
% The final two regimes are observable model-mismatch tests:
%
% nonlinear_interaction:
%   a smooth joint reliability-latency QoS gate;
%
% observable_switching:
%   a public state changes which quality coordinate is operationally
%   decisive. The state is visible, but its interaction with arm quality
%   is not supplied as an explicit linear feature.

    K = cfg.K;
    T = cfg.T;
    d = cfg.contextDim;

    %% 1. Rayleigh fading channel power gain
    rayleighCoeff = ...
        (randn(K, T) + 1i * randn(K, T)) / sqrt(2);

    H = abs(rayleighCoeff).^2;

    %% 2. Natural spectrum occupancy
    occupied = rand(K, T) < cfg.occ_prob;

    %% 3. Background noise
    noisePower = cfg.noise_floor * ones(K, T);

    if isfield(cfg, "noise_fluctuation") ...
            && cfg.noise_fluctuation > 0

        fluctuation = ...
            1 + cfg.noise_fluctuation * randn(K, T);

        fluctuation = max(fluctuation, 0.1);
        noisePower = noisePower .* fluctuation;
    end

    %% 4. Exogenous regime structure
    regime = get_optional_string( ...
        cfg, "environment_regime", "stochastic");

    exogenousInterference = zeros(K, T);
    hiddenInterference = zeros(K, T);
    nonlinearOutcomeInterference = zeros(K, T);

    contaminationMask = false(K, T);
    sweepMask = false(K, T);
    mixedBadChannels = false(K, 1);

    hiddenState = zeros(T, 1);
    hiddenStateMask = false(K, T);

    observableState = zeros(T, 1);
    observableStateSignal = zeros(T, 1);

    switch regime
        case { ...
                "stochastic", ...
                "adaptive_adversarial", ...
                "nonlinear_interaction"}
            % No additional exogenous interference.

        case "observable_switching"
            persistence = get_optional_scalar( ...
                cfg, "observable_state_persistence", 0.97);

            persistence = min(max(persistence, 0), 1);
            currentState = randi(2);

            for t = 1:T

                if t > 1 && rand > persistence
                    currentState = 3 - currentState;
                end

                observableState(t) = currentState;
            end

            observableStateSignal = ...
                2 .* double(observableState == 2) - 1;

        case "contaminated_stochastic"
            probability = get_optional_scalar( ...
                cfg, "contamination_prob", 0.05);

            power = get_optional_scalar( ...
                cfg, "contamination_power", 1.0);

            contaminationMask = rand(K, T) < probability;

            exogenousInterference = ...
                exogenousInterference ...
                + power * double(contaminationMask);

        case "oblivious_sweep"
            width = max(1, min(K, round( ...
                get_optional_scalar(cfg, "sweep_width", 1))));

            power = get_optional_scalar( ...
                cfg, "sweep_power", 1.0);

            for t = 1:T
                firstChannel = mod(t - 1, K) + 1;
                indices = mod( ...
                    (firstChannel - 1) + (0:(width - 1)), ...
                    K) + 1;

                sweepMask(indices, t) = true;
            end

            exogenousInterference = ...
                exogenousInterference ...
                + power * double(sweepMask);

        case "mixed"
            badFraction = get_optional_scalar( ...
                cfg, "mixed_bad_channel_fraction", 0.25);

            power = get_optional_scalar( ...
                cfg, "mixed_interference_power", 0.75);

            numBad = max(1, min(K, round(badFraction * K)));
            ordering = randperm(K);
            mixedBadChannels(ordering(1:numBad)) = true;

            persistentMask = repmat( ...
                mixedBadChannels, 1, T);

            contaminationProbability = ...
                0.5 * get_optional_scalar( ...
                    cfg, "contamination_prob", 0.05);

            contaminationMask = ...
                rand(K, T) < contaminationProbability;

            exogenousInterference = ...
                exogenousInterference ...
                + power * double(persistentMask) ...
                + 0.5 * power * double(contaminationMask);

        case "hidden_markov"
            stateCount = max(2, min(K, round( ...
                get_optional_scalar( ...
                    cfg, "hidden_state_count", 3))));

            persistence = get_optional_scalar( ...
                cfg, "hidden_state_persistence", 0.97);

            badFraction = get_optional_scalar( ...
                cfg, "hidden_state_bad_fraction", 0.25);

            power = get_optional_scalar( ...
                cfg, "hidden_state_power", 0.75);

            persistence = min(max(persistence, 0), 1);
            blockWidth = max(1, min(K, round(badFraction * K)));

            stateGroups = false(K, stateCount);

            for stateIndex = 1:stateCount
                firstChannel = 1 + floor( ...
                    (stateIndex - 1) * K / stateCount);

                indices = mod( ...
                    (firstChannel - 1) + (0:(blockWidth - 1)), ...
                    K) + 1;

                stateGroups(indices, stateIndex) = true;
            end

            currentState = randi(stateCount);

            for t = 1:T

                if t > 1 && rand > persistence
                    alternatives = setdiff(1:stateCount, currentState);
                    currentState = alternatives( ...
                        randi(numel(alternatives)));
                end

                hiddenState(t) = currentState;
                hiddenStateMask(:, t) = ...
                    stateGroups(:, currentState);
            end

            hiddenInterference = ...
                power * double(hiddenStateMask);

        otherwise
            error("Unknown environment regime: %s", regime);
    end

    contextNoisePower = ...
        noisePower + exogenousInterference;

    %% 5. Public SNR quality
    snrRaw = cfg.P_tx * H ...
        ./ max(contextNoisePower, realmin);

    absoluteSnrFeature = snrRaw ./ (snrRaw + 1);

    if ismember(regime, [ ...
            "nonlinear_interaction", ...
            "observable_switching"])

        % Relative SNR quality is a robust public normalization: it keeps
        % the intended model-mismatch geometry stable across fading scale.
        snrFeature = columnwise_rank_quality( ...
            absoluteSnrFeature);
    else
        snrFeature = absoluteSnrFeature;
    end

    %% 6. Public delay quality
    if regime == "nonlinear_interaction"

        delayFloor = get_optional_scalar( ...
            cfg, "nonlinear_delay_floor", 0.08);

        delaySpan = get_optional_scalar( ...
            cfg, "nonlinear_delay_span", 0.84);

        delayGood = ...
            delayFloor + delaySpan .* rand(K, T);

        delayGood = min(max(delayGood, 0.02), 0.98);
        delayRaw = 1 ./ delayGood - 1;

    elseif regime == "observable_switching"

        delayNoise = get_optional_scalar( ...
            cfg, "observable_delay_noise", 0.06);

        % High relative-SNR channels incur larger queue/processing delay.
        % This creates a realistic throughput-latency tradeoff.
        delayGood = ...
            1 - snrFeature ...
            + delayNoise .* randn(K, T);

        delayGood = min(max(delayGood, 0.04), 0.96);
        delayRaw = 1 ./ delayGood - 1;

    else

        delayRaw = cfg.delay_base ...
            + cfg.delay_noise * randn(K, T) ...
            + 0.5 * (1 - snrFeature);

        delayRaw = max(delayRaw, 0.01);
        delayGood = 1 ./ (1 + delayRaw);
    end

    %% 7. Public fourth feature
    available = 1 - double(occupied);
    fourthFeature = available;

    if regime == "observable_switching"

        lowValue = get_optional_scalar( ...
            cfg, "observable_state_feature_low", 0.15);

        highValue = get_optional_scalar( ...
            cfg, "observable_state_feature_high", 0.70);

        availabilityWeight = get_optional_scalar( ...
            cfg, "observable_availability_weight", 0.15);

        stateFeature = lowValue .* ones(1, T);
        stateFeature(observableState == 2) = highValue;

        fourthFeature = repmat(stateFeature, K, 1) ...
            + availabilityWeight .* available;

        fourthFeature = min(max(fourthFeature, 0), 1);
    end

    %% 8. Observable nonlinear physical penalties
    switch regime
        case "nonlinear_interaction"
            snrThreshold = get_optional_scalar( ...
                cfg, "nonlinear_snr_threshold", 0.55);

            delayThreshold = get_optional_scalar( ...
                cfg, "nonlinear_delay_threshold", 0.55);

            steepness = get_optional_scalar( ...
                cfg, "nonlinear_gate_steepness", 18.0);

            power = get_optional_scalar( ...
                cfg, "nonlinear_interaction_power", 0.60);

            exponent = get_optional_scalar( ...
                cfg, "nonlinear_interaction_exponent", 1.50);

            snrGate = logistic_gate( ...
                snrFeature, snrThreshold, steepness);

            delayGate = logistic_gate( ...
                delayGood, delayThreshold, steepness);

            jointGate = snrGate .* delayGate;

            nonlinearOutcomeInterference = ...
                power .* (1 - jointGate) .^ max(exponent, 1);

        case "observable_switching"
            power = get_optional_scalar( ...
                cfg, "observable_switch_power", 0.60);

            steepness = get_optional_scalar( ...
                cfg, "observable_gate_steepness", 18.0);

            snrThreshold = get_optional_scalar( ...
                cfg, "observable_snr_threshold", 0.58);

            delayThreshold = get_optional_scalar( ...
                cfg, "observable_delay_threshold", 0.58);

            snrGate = logistic_gate( ...
                snrFeature, snrThreshold, steepness);

            delayGate = logistic_gate( ...
                delayGood, delayThreshold, steepness);

            for t = 1:T

                if observableState(t) == 1
                    activeGate = snrGate(:, t);
                else
                    activeGate = delayGate(:, t);
                end

                nonlinearOutcomeInterference(:, t) = ...
                    power .* (1 - activeGate) .^ 1.5;
            end
    end

    physicalNoisePower = ...
        contextNoisePower ...
        + hiddenInterference ...
        + nonlinearOutcomeInterference;

    %% 9. Context tensor
    context = zeros(d, K, T);

    if d ~= 4
        error("Current context design requires cfg.contextDim = 4.");
    end

    context(1, :, :) = 1;
    context(2, :, :) = reshape(snrFeature, 1, K, T);
    context(3, :, :) = reshape(delayGood, 1, K, T);
    context(4, :, :) = reshape(fourthFeature, 1, K, T);

    %% 10. Save environment
    env.H = H;
    env.snrRaw = snrRaw;
    env.absoluteSnrFeature = absoluteSnrFeature;
    env.snrFeature = snrFeature;

    env.occupied = occupied;
    env.noisePower = physicalNoisePower;
    env.contextNoisePower = contextNoisePower;
    env.exogenousInterference = exogenousInterference;
    env.hiddenInterference = hiddenInterference;
    env.nonlinearOutcomeInterference = ...
        nonlinearOutcomeInterference;

    env.delayRaw = delayRaw;
    env.delayGood = delayGood;
    env.fourthFeature = fourthFeature;

    env.context = context;
    env.contextDim = d;

    env.fc_GHz = cfg.fc_GHz;
    env.fc = cfg.fc;

    env.regime = regime;
    env.contaminationMask = contaminationMask;
    env.sweepMask = sweepMask;
    env.mixedBadChannels = mixedBadChannels;

    env.hiddenState = hiddenState;
    env.hiddenStateMask = hiddenStateMask;

    env.observableState = observableState;
    env.observableStateSignal = observableStateSignal;

end


function output = columnwise_rank_quality(input)

    [K, T] = size(input);
    output = zeros(K, T);

    if K == 1
        output(:) = 1;
        return;
    end

    qualityGrid = linspace(0.05, 0.95, K)';

    for t = 1:T
        [~, ordering] = sort(input(:, t), "ascend");
        output(ordering, t) = qualityGrid;
    end

end


function value = logistic_gate(input, threshold, steepness)

    steepness = max(steepness, 0);
    value = 1 ./ (1 + exp( ...
        -steepness .* (input - threshold)));

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


function value = get_optional_string(inputStruct, fieldName, defaultValue)

    fieldName = char(fieldName);

    if isfield(inputStruct, fieldName)
        value = lower(string(inputStruct.(fieldName)));
    else
        value = lower(string(defaultValue));
    end

end
