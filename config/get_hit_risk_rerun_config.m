function suite = get_hit_risk_rerun_config(mode)
%GET_HIT_RISK_RERUN_CONFIG Targeted four-way risk-alignment rerun.

    if nargin < 1
        mode = "smoke";
    end

    mode = lower(string(mode));
    suite.mode = mode;
    suite.outputRoot = fullfile( ...
        "results", "hit_risk_alignment", char(mode));

    switch mode
        case "smoke"
            suite.T = 300;
            suite.seedList = 97001:97002;

        case "quick"
            suite.T = 2000;
            suite.seedList = 97001:97005;

        case "full"
            suite.T = 5000;
            suite.seedList = 97001:97020;

        otherwise
            error("Unknown hit-risk rerun mode: %s", mode);
    end

    suite.adversaryType = "contextual_expert";

end
