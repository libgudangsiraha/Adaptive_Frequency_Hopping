function [key, signature] = build_experiment_key( ...
    cfg, learnerType, adversaryType)
%BUILD_EXPERIMENT_KEY Stable disk-cache key for one pair configuration.

    cfgKey = cfg;
    executionFields = [ ...
        "resume", "use_parallel", "parallel_workers", ...
        "checkpoint_root", "auto_start_parallel_pool"];

    for index = 1:numel(executionFields)
        fieldName = char(executionFields(index));
        if isfield(cfgKey, fieldName)
            cfgKey = rmfield(cfgKey, fieldName);
        end
    end

    cfgKey = orderfields(cfgKey);
    signature = char( ...
        lower(string(learnerType)) + "|" ...
        + lower(string(adversaryType)) + "|" ...
        + string(jsonencode(cfgKey)));

    hash = sha256_text(signature);
    regime = get_optional_string(cfg, ...
        "environment_regime", "stochastic");

    prefix = sprintf('%s__%s__%s__K%d_T%d__', ...
        sanitize_token(learnerType), ...
        sanitize_token(adversaryType), ...
        sanitize_token(regime), cfg.K, cfg.T);

    key = [prefix, hash(1:16)];

end


function hash = sha256_text(textValue)
% Portable deterministic cache hash (four modular moments).

    values = double(uint8(textValue));
    positions = 1:numel(values);
    modulus = 2^32 - 5;

    h1 = mod(sum(values), modulus);
    h2 = mod(sum(values .* mod(positions, 104729)), modulus);
    h3 = mod(sum(values .* mod(positions.^2, 130363)), modulus);
    h4 = mod(sum(values .* mod(positions.^3, 155921)), modulus);

    hash = lower(sprintf('%08x%08x%08x%08x', ...
        uint32(h1), uint32(h2), uint32(h3), uint32(h4)));

end

function value = sanitize_token(value)

    value = regexprep(char(lower(string(value))), '[^a-z0-9]+', '_');
    value = regexprep(value, '^_+|_+$', '');

end


function value = get_optional_string(inputStruct, fieldName, defaultValue)

    fieldName = char(fieldName);
    if isfield(inputStruct, fieldName)
        value = string(inputStruct.(fieldName));
    else
        value = string(defaultValue);
    end

end
