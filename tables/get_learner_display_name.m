function name = get_learner_display_name(learnerType)
%GET_LEARNER_DISPLAY_NAME Publication-facing learner name.

    switch lower(string(learnerType))
        case "ucb", name = "UCB";
        case "ts", name = "Thompson Sampling";
        case "exp3", name = "EXP3";
        case "exp4p", name = "EXP4.P";
        case "risk_exp4", name = "Risk-aware EXP4";
        case "aufh_exp3pp", name = "AUFH-EXP3++-1";
        case {"lc_inf", "lc_inf_pool"}, name = "LC-Tsallis-INF-Pool";
        case "lc_inf_online", name = "LC-Tsallis-INF-Online";
        case "bc_nodetect", name = "PACT-AFH-Base";
        case "bc_loss_only", name = "PACT-AFH-L";
        case "bc_explore_only", name = "PACT-AFH-T";
        case "bc_detect", name = "PACT-AFH";
        case "bc_old_loss_only", name = "PACT-AFH legacy q-loss";
        case "bc_old_detect", name = "PACT-AFH legacy full";
        case "bc_scale_control", name = "PACT-AFH scale control";
        case "dpact_nodetect", name = "D-PACT-AFH-Base";
        case "dpact_loss_only", name = "D-PACT-AFH-L";
        case "dpact_explore_only", name = "D-PACT-AFH-T";
        case "dpact_detect", name = "D-PACT-AFH";
        case "dpact_safe", name = "D-PACT-Safe";
        otherwise, name = string(learnerType);
    end

end
