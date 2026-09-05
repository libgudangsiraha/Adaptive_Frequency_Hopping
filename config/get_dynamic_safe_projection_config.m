function suite = get_dynamic_safe_projection_config(mode)
%GET_DYNAMIC_SAFE_PROJECTION_CONFIG D-PACT-Safe risk-budget scan.

    if nargin < 1
        mode = "quick";
    end

    mode = lower(string(mode));
    suite.mode = mode;

    suite.outputRoot = fullfile( ...
        "results", "dynamic_safe_projection", char(mode));

    switch mode
        case "smoke"
            suite.T = 300;
            suite.seedList = 97001:97002;
            suite.tauGrid = [0.10, 0.14];

        case "quick"
            suite.T = 3000;
            suite.seedList = 97001:97006;
            suite.tauGrid = [0.09, 0.10, 0.12, 0.14];

        case "full"
            suite.T = 10000;
            suite.seedList = 97001:97020;
            suite.tauGrid = [0.085, 0.09, 0.10, 0.11, 0.12, 0.14];

        otherwise
            error("Unknown D-PACT-Safe mode: %s", mode);
    end

    suite.attackBudget = 1;
    suite.beta = 16;
    suite.nu = 0;

    suite.scanAdversary = "contextual_expert";

    suite.evaluationAdversaries = [ ...
        "random", ...
        "sweep", ...
        "folpetti_ts", ...
        "contextual_expert"];

    suite.referenceLearners = [ ...
        "lc_inf_online", ...
        "risk_exp4", ...
        "aufh_exp3pp", ...
        "dpact_detect"];

end
