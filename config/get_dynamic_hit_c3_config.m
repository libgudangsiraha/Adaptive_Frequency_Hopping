function suite = get_dynamic_hit_c3_config(mode)
%GET_DYNAMIC_HIT_C3_CONFIG External-attacker robustness configuration.
%
% All attackers use one attacked channel per round so that their raw
% goodput, PDR, and jam-hit values are directly comparable.

    if nargin < 1
        mode = "quick";
    end

    mode = lower(string(mode));
    suite.mode = mode;

    suite.outputRoot = fullfile( ...
        "results", "dynamic_hit_c3", char(mode));

    switch mode
        case "smoke"
            suite.T = 300;
            suite.seedList = 95001:95002;
            suite.folpettiMcSamples = 64;

        case "quick"
            suite.T = 3000;
            suite.seedList = 95001:95006;
            suite.folpettiMcSamples = 256;

        case "full"
            suite.T = 10000;
            suite.seedList = 95001:95020;
            suite.folpettiMcSamples = 512;

        otherwise
            error("Unknown dynamic-hit C3 mode: %s", mode);
    end

    suite.attackBudget = 1;

    suite.adversaries = [ ...
        "random", ...
        "sweep", ...
        "folpetti_ts", ...
        "contextual_expert"];

    suite.learners = [ ...
        "ts", ...
        "exp3", ...
        "lc_inf_online", ...
        "risk_exp4", ...
        "aufh_exp3pp", ...
        "dpact_nodetect", ...
        "dpact_detect"];

    suite.defaultBeta = 8;
    suite.defaultNu = 1;
    suite.defaultOperatingPoint = "balanced";

end
