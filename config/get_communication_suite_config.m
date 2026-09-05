function suite = get_communication_suite_config(mode)
%GET_COMMUNICATION_SUITE_CONFIG PACT-AFH v2 experiment design.
%
% Modes:
%   smoke - interface validation
%   quick - working-day diagnostic run
%   full  - final paper-scale evaluation

    if nargin < 1 || strlength(string(mode)) == 0
        mode = "smoke";
    end

    mode = lower(string(mode));
    suite.mode = mode;
    suite.outputRoot = fullfile( ...
        "results", "communication_v2", char(mode));

    switch mode
        case "smoke"
            suite.T = 300;
            suite.mainSeeds = 91001:91002;
            suite.externalSeeds = 91101:91102;
            suite.ablationSeeds = 91201:91202;
            suite.regimeSeeds = 91301:91302;
            suite.paretoSeeds = 91401:91402;
            suite.robustnessSeeds = 91501:91502;
            suite.scalingSeeds = 91601:91602;
            suite.jsrDbGrid = [0, 10];
            suite.predictorPowerGrid = [1, 2];
            suite.attackBudgetGrid = [1, 2];
            suite.KGrid = [8, 12];
            suite.TGrid = [100, 300];
            suite.folpettiMcSamples = 64;

        case "quick"
            suite.T = 3000;
            suite.mainSeeds = 41001:41008;
            suite.externalSeeds = 41101:41106;
            suite.ablationSeeds = 41201:41208;
            suite.regimeSeeds = 41301:41306;
            suite.paretoSeeds = 41401:41406;
            suite.robustnessSeeds = 41501:41506;
            suite.scalingSeeds = 41601:41605;
            suite.jsrDbGrid = [-5, 0, 5, 10, 15];
            suite.predictorPowerGrid = [1, 2, 4];
            suite.attackBudgetGrid = [1, 2, 3, 4];
            suite.KGrid = [8, 12, 16, 32];
            suite.TGrid = [1000, 3000, 10000];
            suite.folpettiMcSamples = 256;

        case "full"
            suite.T = 10000;
            suite.mainSeeds = 31001:31030;
            suite.externalSeeds = 32001:32020;
            suite.ablationSeeds = 33001:33030;
            suite.regimeSeeds = 34001:34020;
            suite.paretoSeeds = 35001:35015;
            suite.robustnessSeeds = 36001:36015;
            suite.scalingSeeds = 37001:37010;
            suite.jsrDbGrid = [-5, 0, 5, 10, 15];
            suite.predictorPowerGrid = [1, 2, 4];
            suite.attackBudgetGrid = [1, 2, 3, 4];
            suite.KGrid = [8, 12, 16, 32];
            suite.TGrid = [1000, 5000, 10000, 20000];
            suite.folpettiMcSamples = 512;

        otherwise
            error("Unknown communication-suite mode: %s", mode);
    end

    suite.mainLearners = [ ...
        "ucb", "ts", "exp3", "exp4p", ...
        "lc_inf_online", "lc_inf_pool", ...
        "risk_exp4", "aufh_exp3pp", ...
        "bc_nodetect", "bc_detect"];

    suite.externalLearners = [ ...
        "ts", "exp3", "lc_inf_online", "aufh_exp3pp", ...
        "bc_nodetect", "bc_detect"];

    suite.ablationLearners = [ ...
        "bc_nodetect", "bc_loss_only", ...
        "bc_explore_only", "bc_detect"];

    suite.externalAdversaries = [ ...
        "random", "sweep", "folpetti_ts", "contextual_expert"];

    suite.regimeNames = [ ...
        "stochastic", "contaminated_stochastic", ...
        "oblivious_sweep", "adaptive_adversarial", "mixed"];
    suite.regimeEnvironment = [ ...
        "stochastic", "contaminated_stochastic", ...
        "stochastic", "stochastic", "mixed"];
    suite.regimeAdversaries = [ ...
        "none", "none", "sweep", ...
        "contextual_expert", "contextual_expert"];
    suite.regimeLearners = [ ...
        "ts", "exp3", "lc_inf_online", ...
        "aufh_exp3pp", "bc_nodetect", "bc_detect"];

    suite.betaGrid = [0, 4, 8];
    suite.nuGrid = [0, 1, 2];
    suite.defaultBeta = 8;
    suite.defaultNu = 1;
    suite.externalAttackBudget = 1;

end
