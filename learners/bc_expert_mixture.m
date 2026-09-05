function [baseProb, expertProb, advice, eta_t, riskInfo] = ...
    bc_expert_mixture(learner, X_t, varargin)
%BC_EXPERT_MIXTURE Partition-expert mixture with Tsallis-FTRL.
%
% Preferred call:
%   bc_expert_mixture(learner, X_t, q_t, t)
%
% Backward-compatible call:
%   bc_expert_mixture(learner, X_t, t)
%
% New q-loss mode uses the currently published q_t before choosing A_t:
%
%   S_t = L_{t-1}^{comm}
%       + beta * (Q_{t-1} + kappa * g_t).

    %% Parse arguments
    if numel(varargin) == 1
        q_t = [];
        t = varargin{1};

    elseif numel(varargin) == 2
        q_t = varargin{1};
        t = varargin{2};

    else
        error( ...
            "bc_expert_mixture expects (learner,X_t,t) " ...
            + "or (learner,X_t,q_t,t).");
    end

    %% Evaluate the hybrid PACT expert class
    advice = evaluate_pact_experts( ...
        X_t, learner.expertBank);

    [K, N] = size(advice);

    if K ~= learner.K || N ~= learner.numExperts
        error("Partition expert advice has an invalid size.");
    end

    %% Current full-information prediction risk
    if isempty(q_t)

        if learner.predictionLossMode == "dual_current"
            error( ...
                "The new q-loss requires current q_t at selection time.");
        end

        currentRawRisk = zeros(N, 1);
        currentNormalizedRisk = zeros(N, 1);
        normalizedQ = [];

    else

        [currentRawRisk, currentNormalizedRisk, normalizedQ] = ...
            bc_expert_prediction_risk(advice, q_t);

    end

    %% Learning-rate schedule
    eta_t = learner.etaScale / sqrt(max(t, 1));

    %% Objective supplied to Tsallis-FTRL
    effectiveExpertLoss = ...
        bc_effective_expert_loss( ...
            learner, ...
            currentNormalizedRisk);

    %% Tsallis-FTRL distribution over experts
    expertProb = tsallis_ftrl_policy( ...
        effectiveExpertLoss, eta_t);

    %% Mixture over actions
    baseProb = advice * expertProb;

    if any(~isfinite(baseProb)) ...
            || any(baseProb < 0) ...
            || sum(baseProb) <= 0

        baseProb = ones(learner.K, 1) / learner.K;
    else
        baseProb = baseProb / sum(baseProb);
    end

    %% Diagnostics
    riskInfo.rawExpertRisk = currentRawRisk;
    riskInfo.normalizedExpertRisk = currentNormalizedRisk;
    riskInfo.q = normalizedQ;
    riskInfo.effectiveExpertLoss = effectiveExpertLoss;
    riskInfo.baseRisk = currentRawRisk' * expertProb;

end
