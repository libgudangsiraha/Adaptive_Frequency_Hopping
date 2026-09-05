clear; clc;

setup_paths();

clear bc_expert_prediction_risk
clear bc_effective_expert_loss
clear learner_update
rehash

%% Deterministic dual-channel test
K = 4;
N = 3;
beta = 2.0;
currentRiskWeight = 1.0;

advice = [
    0.70, 0.10, 0.25;
    0.10, 0.60, 0.25;
    0.10, 0.20, 0.25;
    0.10, 0.10, 0.25
];

q_t = [
    0.10;
    0.50;
    0.20;
    0.20
];

[rawRisk, normalizedRisk] = ...
    bc_expert_prediction_risk(advice, q_t);

learner = make_test_learner( ...
    K, N, beta, currentRiskWeight);

learner.cumCommExpertLoss = [
    1.0;
    2.0;
    3.0
];

learner.cumPredictionExpertRisk = [
     0.10;
    -0.20;
     0.30
];

expectedEffective = ...
    learner.cumCommExpertLoss ...
    + beta .* ( ...
        learner.cumPredictionExpertRisk ...
        + currentRiskWeight .* normalizedRisk);

computedEffective = ...
    bc_effective_expert_loss( ...
        learner, normalizedRisk);

tol = 1e-12;

assert(norm( ...
    computedEffective - expectedEffective, Inf) < tol, ...
    "Dual-channel selection score is incorrect.");

%% beta = 0 must reduce exactly to communication-only FTRL
learnerZero = learner;
learnerZero.detectBeta = 0;

effectiveZero = ...
    bc_effective_expert_loss( ...
        learnerZero, normalizedRisk);

assert(norm( ...
    effectiveZero ...
    - learnerZero.cumCommExpertLoss, Inf) < tol, ...
    "beta=0 does not recover communication-only aggregation.");

%% One exact bandit update
feedback.action = 2;
feedback.reward = 0.4;
feedback.pi = [
    0.20;
    0.30;
    0.10;
    0.40
];
feedback.q = q_t;

aux.advice = advice;
aux.currentExpertRiskRaw = rawRisk;
aux.currentExpertRiskNormalized = normalizedRisk;

X_t = zeros(1, K);
t = 1;
cfg = struct();

oldComm = learner.cumCommExpertLoss;
oldRisk = learner.cumPredictionExpertRisk;
oldRawRisk = learner.cumulativeExpectedExpertRisk;

communicationLossHat = zeros(K, 1);
communicationLossHat(2) = ...
    (1 - feedback.reward) / feedback.pi(2);

expectedCommIncrement = ...
    advice' * communicationLossHat;

updated = learner_update( ...
    learner, X_t, feedback, aux, t, cfg);

assert(norm( ...
    updated.cumCommExpertLoss ...
    - (oldComm + expectedCommIncrement), Inf) < tol, ...
    "Communication-loss channel update is incorrect.");

assert(norm( ...
    updated.cumPredictionExpertRisk ...
    - (oldRisk + normalizedRisk), Inf) < tol, ...
    "Prediction-risk channel update is incorrect.");

assert(norm( ...
    updated.cumulativeExpectedExpertRisk ...
    - (oldRawRisk + rawRisk), Inf) < tol, ...
    "Raw expert-risk diagnostic update is incorrect.");

assert(norm( ...
    updated.cumExpertLoss ...
    - updated.cumCommExpertLoss, Inf) < tol, ...
    "Backward-compatible cumExpertLoss alias is incorrect.");

assert(updated.numUpdates == 1);

fprintf("\nRaw expert risk:\n");
disp(rawRisk);

fprintf("Normalized expert risk:\n");
disp(normalizedRisk);

fprintf("Effective dual-channel score:\n");
disp(computedEffective);

fprintf("Communication expert-loss increment:\n");
disp(expectedCommIncrement);

disp("Exact dual-channel q-loss test passed.");


function learner = make_test_learner( ...
    K, N, beta, currentRiskWeight)

    learner.type = "bc_loss_only";
    learner.K = K;
    learner.numExperts = N;

    learner.predictionLossMode = "dual_current";

    learner.usePredictionLoss = true;
    learner.useNewPredictionLoss = true;
    learner.useLegacyPredictionLoss = false;
    learner.scaleCommunicationLoss = false;
    learner.usePredictionExploration = false;

    learner.detectBeta = beta;
    learner.currentRiskWeight = currentRiskWeight;
    learner.detectLambda = 0.5;

    learner.cumCommExpertLoss = zeros(N, 1);
    learner.cumPredictionExpertRisk = zeros(N, 1);
    learner.cumLegacyExpertLoss = zeros(N, 1);
    learner.cumExpertLoss = zeros(N, 1);

    learner.cumulativeExpectedExpertRisk = zeros(N, 1);

    learner.lastCurrentExpertRiskRaw = zeros(N, 1);
    learner.lastCurrentExpertRiskNormalized = zeros(N, 1);

    learner.maxEstimatedExpertLoss = 0;
    learner.maxEstimatedCommExpertLoss = 0;
    learner.maxLegacyEstimatedExpertLoss = 0;
    learner.maxAbsPredictionRiskSignal = 0;

    learner.numUpdates = 0;

end
