function expertCfg = get_policy_expert_config(baseCfg)
%GET_POLICY_EXPERT_CONFIG Configuration of generic contextual policy experts.
%
% Used by:
%   - EXP4.P
%   - Risk-aware EXP4
%
% These experts are fixed linear-softmax policies.
% They do not use q_t and do not use context partitions.

    expertCfg.K = baseCfg.K;

    % Context rows:
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

    % Nonnegative weight grid:
    % n1 + n2 + n3 = gridLevel
    expertCfg.gridLevel = 4;

    % Lower temperature gives more nearly deterministic advice.
    expertCfg.temperatures = [0.05, 0.20, 0.80];

    % Required as a neutral reference expert.
    expertCfg.includeUniform = true;

    % Current context features are already engineered/scaled.
    % Leave them unchanged by default.
    expertCfg.normalizePerRound = false;

end