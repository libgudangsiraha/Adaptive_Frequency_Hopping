function diagCfg = get_model_diagnostic_config(mode)
%GET_MODEL_DIAGNOSTIC_CONFIG Fast model-class and optimization diagnosis.
%
% Modes:
%   smoke : syntax/interface check
%   quick : recommended first diagnostic run
%   full  : higher-confidence diagnostic run

    if nargin < 1
        mode = "quick";
    end

    mode = lower(string(mode));
    diagCfg.mode = mode;

    switch mode
        case "smoke"
            diagCfg.T = 300;
            diagCfg.seedList = 86001:86002;
            diagCfg.syntheticT = 600;
            diagCfg.syntheticSeeds = 2;

        case "quick"
            diagCfg.T = 2000;
            diagCfg.seedList = 86001:86005;
            diagCfg.syntheticT = 5000;
            diagCfg.syntheticSeeds = 5;

        case "full"
            diagCfg.T = 10000;
            diagCfg.seedList = 86001:86020;
            diagCfg.syntheticT = 20000;
            diagCfg.syntheticSeeds = 10;

        otherwise
            error("Unknown diagnostic mode: %s", mode);
    end

    diagCfg.trainFraction = 0.70;
    diagCfg.ridgeLambda = 1e-4;

    % Exogenous scenarios are used for model-class diagnosis because every
    % learner then sees the same reward surface.
    diagCfg.oracleScenarios = ["none", "sweep"];

    % Closed-loop scenarios are used only for online backbone diagnosis.
    diagCfg.onlineScenarios = ["none", "contextual_expert"];

    diagCfg.syntheticTasks = [ ...
        "linear_monotone", ...
        "interaction", ...
        "xor", ...
        "band_pass", ...
        "weight_flip"];

    diagCfg.outputRoot = fullfile( ...
        "results", "model_diagnostics", char(mode));

end
