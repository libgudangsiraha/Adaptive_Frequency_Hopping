function outcomes = compute_all_arm_outcomes( ...
    h_t, occ_t, noise_t, jammed_t, cfg)
%COMPUTE_ALL_ARM_OUTCOMES Vectorized communication outcomes for all arms.
%
% The main v2 modes align learner reward and delivered goodput: when a
% packet is in outage, both are zero.

    h = h_t(:);
    occupied = logical(occ_t(:));
    jammed = logical(jammed_t(:));
    noisePower = max(noise_t(:), realmin);

    if any([numel(h), numel(occupied), numel(jammed)] ~= numel(noisePower))
        error("Arm-outcome vectors have inconsistent sizes.");
    end

    interference = cfg.jam_strength .* double(jammed);
    signalPower = cfg.P_tx .* h;
    sinr = signalPower ./ (noisePower + interference);
    sinrDb = 10 .* log10(max(sinr, realmin));

    rawSpectralEfficiency = log2(1 + sinr);

    thresholdDb = get_optional_scalar( ...
        cfg, "sinr_outage_threshold_dB", 3.0);

    packetSuccess = ~occupied & sinrDb >= thresholdDb;

    cap = get_optional_scalar(cfg, "mcs_cap_bps_hz", 4.0);
    cap = max(cap, realmin);

    cappedSpectralEfficiency = min(rawSpectralEfficiency, cap);
    adaptiveGoodputBps = ...
        get_optional_scalar(cfg, "bandwidth_Hz", 1.0) ...
        .* rawSpectralEfficiency .* double(packetSuccess);

    cappedGoodputBps = ...
        get_optional_scalar(cfg, "bandwidth_Hz", 1.0) ...
        .* cappedSpectralEfficiency .* double(packetSuccess);

    fixedGoodputBps = ...
        get_optional_scalar(cfg, "packet_bits", 1000) ...
        ./ max(get_optional_scalar(cfg, "slot_duration_s", 1e-3), realmin) ...
        .* double(packetSuccess);

    mode = lower(string(get_optional_value( ...
        cfg, "reward_mode", "outage_capped")));

    switch mode
        case "legacy_shannon"
            legacyRate = cfg.B .* rawSpectralEfficiency;
            legacyRate(occupied) = 0;
            reward = min(max(legacyRate ./ cfg.max_rate_norm, 0), 1);
            mainRate = legacyRate;
            mainGoodputBps = adaptiveGoodputBps;

        case "outage_shannon"
            delivered = rawSpectralEfficiency .* double(packetSuccess);
            reward = min(max(delivered ./ cfg.max_rate_norm, 0), 1);
            mainRate = cfg.B .* delivered;
            mainGoodputBps = adaptiveGoodputBps;

        case "outage_capped"
            delivered = cappedSpectralEfficiency .* double(packetSuccess);
            reward = min(max(delivered ./ cap, 0), 1);
            mainRate = cfg.B .* delivered;
            mainGoodputBps = cappedGoodputBps;

        case "fixed_packet"
            reward = double(packetSuccess);
            mainRate = reward;
            mainGoodputBps = fixedGoodputBps;

        otherwise
            error("Unknown reward_mode: %s", mode);
    end

    berBpsk = 0.5 .* erfc(sqrt(max(sinr, 0)));
    berBpsk(occupied) = 0.5;

    packetBits = max(1, round(get_optional_scalar( ...
        cfg, "packet_bits", 1000)));

    packetErrorProxy = ...
        1 - (1 - min(max(berBpsk, 0), 0.5)).^packetBits;

    outcomes.reward = reward;
    outcomes.rate = mainRate;
    outcomes.sinr = sinr;
    outcomes.sinrDb = sinrDb;
    outcomes.signalPower = signalPower;
    outcomes.noisePower = noisePower;
    outcomes.occupied = double(occupied);
    outcomes.jammed = double(jammed);
    outcomes.interference = interference;

    outcomes.rawSpectralEfficiency = rawSpectralEfficiency;
    outcomes.cappedSpectralEfficiency = cappedSpectralEfficiency;
    outcomes.packetSuccess = double(packetSuccess);
    outcomes.pdr = double(packetSuccess);

    outcomes.goodputBps = mainGoodputBps;
    outcomes.goodputMbps = mainGoodputBps ./ 1e6;
    outcomes.adaptiveGoodputMbps = adaptiveGoodputBps ./ 1e6;
    outcomes.cappedGoodputMbps = cappedGoodputBps ./ 1e6;
    outcomes.fixedGoodputMbps = fixedGoodputBps ./ 1e6;

    outcomes.berBpsk = berBpsk;
    outcomes.packetErrorProxy = packetErrorProxy;
    outcomes.retransmission = 1 - double(packetSuccess);
    outcomes.rewardMode = mode;

end


function value = get_optional_scalar(inputStruct, fieldName, defaultValue)

    value = get_optional_value(inputStruct, fieldName, defaultValue);

    if ~isscalar(value) || ~isfinite(value)
        error("Configuration field '%s' must be finite.", fieldName);
    end

end


function value = get_optional_value(inputStruct, fieldName, defaultValue)

    fieldName = char(fieldName);

    if isfield(inputStruct, fieldName)
        value = inputStruct.(fieldName);
    else
        value = defaultValue;
    end

end
