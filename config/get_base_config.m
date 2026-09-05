function cfg = get_base_config()
%GET_BASE_CONFIG Base configuration for PACT-AFH v2 experiments.
%
% v2 aligns the learner reward with packet delivery, uses a finite-rate
% physical readout, supports a hybrid linear/partition PACT expert bank,
% and enables persistent checkpoint/resume execution.

    %% Experiment size
    cfg.K = 12;
    cfg.T = 1000;

    cfg.seed = 2026;
    cfg.numSeeds = 10;
    cfg.seedList = cfg.seed:(cfg.seed + cfg.numSeeds - 1);

    %% Frequency labels
    cfg.fc_GHz = linspace(12, 18, cfg.K);
    cfg.fc = cfg.fc_GHz * 1e9;

    %% Communication environment (normalized simulation units)
    cfg.P_tx = 1.0;
    cfg.B = 1.0;
    cfg.noise_floor = 0.05;
    cfg.noise_fluctuation = 0.0;
    cfg.occ_prob = 0.15;
    cfg.jam_strength = 2.0;
    cfg.M_jam = 2;
    cfg.max_rate_norm = 6;

    %% Packet-aligned physical model
    % Modes:
    %   legacy_shannon : old ungated learner reward; appendix only
    %   outage_shannon : failed packets give zero reward, uncapped rate
    %   outage_capped  : failed packets give zero reward, capped MCS rate
    %   fixed_packet   : one fixed payload per successful slot
    cfg.reward_mode = "outage_capped";
    cfg.bandwidth_Hz = 1e6;
    cfg.packet_bits = 1000;
    cfg.slot_duration_s = 1e-3;
    cfg.sinr_outage_threshold_dB = 3.0;
    cfg.mcs_cap_bps_hz = 4.0;
    cfg.switch_cost = 0.0;

    %% Environment regime
    cfg.environment_regime = "stochastic";
    cfg.contamination_prob = 0.05;
    cfg.contamination_power = 1.0;
    cfg.sweep_width = 1;
    cfg.sweep_power = 1.0;
    cfg.mixed_bad_channel_fraction = 0.25;
    cfg.mixed_interference_power = 0.75;

    %% Hidden-state environment
    cfg.hidden_state_count = 3;
    cfg.hidden_state_persistence = 0.97;
    cfg.hidden_state_bad_fraction = 0.25;
    cfg.hidden_state_power = 0.75;

    %% Observable nonlinear QoS-gate environment
    % Public relative-SNR quality and an independent delay-quality signal
    % must jointly clear two smooth QoS thresholds. This creates a
    % physically interpretable reliability-latency AND gate.
    cfg.nonlinear_snr_threshold = 0.55;
    cfg.nonlinear_delay_threshold = 0.55;
    cfg.nonlinear_gate_steepness = 18.0;
    cfg.nonlinear_interaction_power = 0.60;
    cfg.nonlinear_interaction_exponent = 1.50;
    cfg.nonlinear_delay_floor = 0.08;
    cfg.nonlinear_delay_span = 0.84;

    %% Observable coefficient-switching environment
    % A public system-load indicator occupies the fourth context feature.
    % In the channel-limited state, relative SNR determines viability;
    % in the deadline-limited state, delay quality determines viability.
    % SNR and delay are intentionally traded off, so one global set of
    % linear coefficients cannot be optimal in both public states.
    cfg.observable_state_persistence = 0.97;
    cfg.observable_switch_power = 0.60;
    cfg.observable_gate_steepness = 18.0;
    cfg.observable_snr_threshold = 0.58;
    cfg.observable_delay_threshold = 0.58;
    cfg.observable_delay_noise = 0.06;
    cfg.observable_state_feature_low = 0.15;
    cfg.observable_state_feature_high = 0.70;
    cfg.observable_availability_weight = 0.15;

    %% Fast model-mismatch preflight
    cfg.model_mismatch_oracle_ridge = 0.05;
    cfg.model_mismatch_train_fraction = 0.60;
    cfg.model_mismatch_min_capture_gain = 0.005;

    %% Context features
    % [bias; snrFeature; delayGood; availability]
    cfg.contextDim = 4;
    cfg.delay_base = 1.0;
    cfg.delay_noise = 0.1;

    %% PACT expert bank
    % Main model = continuous linear experts + multi-scale partitions.
    cfg.pact_expert_bank_mode = "hybrid";
    cfg.linear_expert_grid_level = 4;
    cfg.linear_expert_temperatures = [0.05, 0.20, 0.80];

    %% Legacy prediction-risk objective
    cfg.detect_lambda = 0.2;

    %% New dual-channel q-loss
    cfg.detect_beta = 8.0;
    cfg.current_risk_weight = 1.0;

    %% Prediction-aware directional exploration
    cfg.explore_epsilon = 1e-3;
    cfg.explore_nu = 1.0;
    cfg.explore_uniform_floor = 0.05;

    %% Predictable decaying exploration schedule
    cfg.explore_scale = 1.0;
    cfg.explore_beta = 0.5;
    cfg.explore_gamma_max = 0.30;

    %% Predictor-strength control
    cfg.predictor_power = 1.0;

    %% LC-Tsallis-INF fairness variants
    cfg.lc_context_pool_size = 200;
    cfg.lc_online_buffer_size = 200;
    cfg.lc_sigma_update_period = 5;

    %% Dynamic PACT master (LC-INF + local nonlinear learner)
    % Internal learner types:
    %   dpact_nodetect, dpact_loss_only,
    %   dpact_explore_only, dpact_detect.
    cfg.dynamic_master_eta_scale = 1.0;
    cfg.dynamic_master_gamma_scale = 0.25;
    cfg.dynamic_master_gamma_max = 0.10;
    cfg.dynamic_master_uniform_floor = 0.02;
    cfg.dynamic_lc_anchor_scale = 0.50;
    cfg.dynamic_lc_anchor_floor = 0.0;
    cfg.dynamic_local_prior_penalty = 1.0;
    cfg.dynamic_force_base = "none";  % none | lc | local
    cfg.dynamic_offpolicy_ratio_cap = 20.0;

    %% Partitioned local-linear base learner
    cfg.local_linear_feature_rows = [2, 3, 4];
    cfg.local_linear_bins = [4, 4, 2];
    cfg.local_linear_ridge = 0.10;
    cfg.local_linear_temperature = 0.15;
    cfg.local_linear_min_temperature = 0.04;
    cfg.local_linear_temperature_decay = 0.10;
    cfg.local_linear_ucb_scale = 0.15;
    cfg.local_linear_forgetting = 0.9995;

    %% Legacy fields retained for archived scripts
    cfg.detect_window = 50;
    cfg.explore_quality_weights = [0.6; 0.4];
    cfg.explore_available_floor = 0.05;
    cfg.explore_unavailable_weight = 0.02;

    %% Diagnostics
    cfg.moving_window = 50;

    %% Result-storage controls
    cfg.store_full_histories = true;
    cfg.store_metric_timeseries = true;

    %% Persistent execution controls
    cfg.resume = true;
    cfg.use_parallel = true;
    cfg.parallel_workers = 0;  % 0 = MATLAB local default
    cfg.checkpoint_root = "";

    %% FOLPETTI white-box distribution approximation
    cfg.folpetti_mc_samples = 128;

end
