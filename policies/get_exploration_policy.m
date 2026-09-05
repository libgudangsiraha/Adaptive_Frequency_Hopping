function e = get_exploration_policy(X_t, cfg)
%GET_EXPLORATION_POLICY Compute exploration policy e*(x).

    K = cfg.K;

    switch lower(cfg.lc_exploration_type)

        case "uniform"
            e = ones(K, 1) / K;

        otherwise
            error("Unknown exploration type: %s", cfg.lc_exploration_type);
    end

end