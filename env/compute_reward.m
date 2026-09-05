function [reward, rate, info] = compute_reward( ...
    a, h_t, occ_t, noise_t, jammed_t, cfg)
%COMPUTE_REWARD Backward-compatible selected-arm wrapper.

    outcomes = compute_all_arm_outcomes( ...
        h_t, occ_t, noise_t, jammed_t, cfg);

    reward = outcomes.reward(a);
    rate = outcomes.rate(a);

    fields = fieldnames(outcomes);

    for index = 1:numel(fields)
        name = fields{index};
        value = outcomes.(name);

        if isnumeric(value) || islogical(value)
            if numel(value) == numel(h_t)
                info.(name) = value(a);
            else
                info.(name) = value;
            end
        else
            info.(name) = value;
        end
    end

    % Compatibility with v1 field name.
    info.spectralEfficiency = info.rawSpectralEfficiency;

end
