function suite = get_dynamic_pact_validation_config(mode)
%GET_DYNAMIC_PACT_VALIDATION_CONFIG Targeted D-PACT-AFH validation.

    if nargin < 1
        mode = "smoke";
    end

    mode = lower(string(mode));
    suite.mode = mode;
    suite.outputRoot = fullfile( ...
        "results", "dynamic_pact_validation", char(mode));

    switch mode
        case "smoke"
            suite.T = 120;
            suite.seedList = 94001:94002;
            suite.syntheticT = 200;
            suite.syntheticSeeds = 1;

        case "quick"
            suite.T = 2000;
            suite.seedList = 94001:94005;
            suite.syntheticT = 4000;
            suite.syntheticSeeds = 3;

        case "full"
            suite.T = 10000;
            suite.seedList = 94001:94020;
            suite.syntheticT = 20000;
            suite.syntheticSeeds = 10;

        otherwise
            error("Unknown dynamic validation mode: %s", mode);
    end

    suite.adversaries = ["none", "contextual_expert"];
    suite.syntheticTasks = [ ...
        "linear_monotone", ...
        "interaction", ...
        "xor", ...
        "band_pass", ...
        "weight_flip"];

end
