function suite = get_dynamic_hit_pareto_config(mode)
%GET_DYNAMIC_HIT_PARETO_CONFIG Dynamic hit-risk beta-nu scan.
%
% smoke : interface validation
% quick : working diagnostic scan
% full  : publication-scale operating-point scan

    if nargin < 1
        mode = "quick";
    end

    mode = lower(string(mode));
    suite.mode = mode;

    suite.outputRoot = fullfile( ...
        "results", "dynamic_hit_pareto", char(mode));

    switch mode
        case "smoke"
            suite.T = 300;
            suite.seedList = 94001:94002;
            suite.betaGrid = [0, 8];
            suite.nuGrid = [0, 1];

        case "quick"
            suite.T = 2000;
            suite.seedList = 94001:94005;
            suite.betaGrid = [0, 4, 8, 16];
            suite.nuGrid = [0, 1, 2];

        case "full"
            suite.T = 5000;
            suite.seedList = 94001:94015;
            suite.betaGrid = [0, 2, 4, 8, 16];
            suite.nuGrid = [0, 0.5, 1, 2];

        otherwise
            error("Unknown dynamic-hit Pareto mode: %s", mode);
    end

    suite.adversaryType = "contextual_expert";
    suite.attackBudget = 2;
    suite.defaultBeta = 8;
    suite.defaultNu = 1;

    suite.baselineLearners = [ ...
        "lc_inf_online", ...
        "risk_exp4", ...
        "aufh_exp3pp", ...
        "dpact_nodetect"];

end
