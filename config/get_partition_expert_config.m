function expertCfg = get_partition_expert_config(baseCfg)
%GET_PARTITION_EXPERT_CONFIG Configuration for arm-wise partition experts.
%
% These experts are used by:
%   - B+C without detectability
%   - B+C with detectability
%
% Each arm's local context is partitioned independently.

    expertCfg.K = baseCfg.K;

    %% Context rows
    % X_t rows:
    % 1 = bias
    % 2 = SNR feature
    % 3 = delay-good feature
    % 4 = availability
    expertCfg.featureRows = [2, 3, 4];

    expertCfg.featureNames = [
        "snr"
        "delay"
        "availability"
    ];

    %% Fixed feature ranges
    % Partition boundaries must be fixed globally.
    % Do not normalize independently in every round.
    expertCfg.featureMin = [0; 0; 0];
    expertCfg.featureMax = [1; 1; 1];

    %% Binary features
    % Availability is treated as a binary category and remains 0/1.
    expertCfg.binaryFeatureMask = [
        false
        false
        true
    ];

    %% Multi-scale arm-wise partitions
    %
    % Columns:
    % [SNR bins, delay bins, availability bins]
    expertCfg.partitionScales = [
        2, 2, 2
        3, 3, 2
        4, 4, 2
    ];

    expertCfg.scaleNames = [
        "coarse"
        "medium"
        "fine"
    ];

    %% Feature-weight simplex grid
    % n1 + n2 + n3 = gridLevel
    expertCfg.gridLevel = 4;

    %% Softmax temperatures
    expertCfg.temperatures = [0.05, 0.20, 0.80];

    %% Neutral expert
    expertCfg.includeUniform = true;

end