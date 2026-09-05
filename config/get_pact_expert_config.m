function cfg = get_pact_expert_config(baseCfg)
%GET_PACT_EXPERT_CONFIG Hybrid continuous-linear/partition expert class.

    cfg.partitionCfg = get_partition_expert_config(baseCfg);
    cfg.K = baseCfg.K;
    cfg.mode = lower(string(get_optional_value( ...
        baseCfg, "pact_expert_bank_mode", "hybrid")));

    cfg.linearFeatureRows = cfg.partitionCfg.featureRows;
    cfg.linearFeatureNames = cfg.partitionCfg.featureNames;
    cfg.linearGridLevel = get_optional_scalar( ...
        baseCfg, "linear_expert_grid_level", 4);
    cfg.linearTemperatures = get_optional_value( ...
        baseCfg, "linear_expert_temperatures", [0.05, 0.20, 0.80]);

end


function value = get_optional_scalar(inputStruct, fieldName, defaultValue)

    value = get_optional_value(inputStruct, fieldName, defaultValue);

    if ~isscalar(value) || ~isfinite(value)
        error("Configuration field '%s' must be scalar.", fieldName);
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
