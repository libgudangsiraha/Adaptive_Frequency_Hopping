function [a_t, pi_t, aux, learner] = learner_select( ...
    learner, X_t, q_t, t, cfg)
%LEARNER_SELECT Generate learner distribution and sample one action.
%
% Inputs:
%   learner - current learner state
%   X_t     - d x K current context
%   q_t     - K x 1 public adversary prediction distribution
%   t       - current time
%   cfg     - base configuration
%
% Outputs:
%   a_t     - selected arm
%   pi_t    - K x 1 learner action distribution
%   aux     - auxiliary information required by learner_update

    %#ok<INUSD>

    K = learner.K;
    aux = struct();

    % Most learners sample their action from pi_t.
    % TS directly samples posterior values and therefore sets a_t itself.
    actionAlreadySampled = false;
    a_t = [];

    switch learner.type

        case "exp3"
            % EXP3 deliberately ignores X_t and q_t.
            logW = learner.logWeights(:);

            shifted = logW - max(logW);
            baseProb = exp(shifted);
            baseProb = baseProb / sum(baseProb);

            gamma = learner.gamma;

            pi_t = ...
                (1 - gamma) * baseProb ...
                + gamma * ones(K, 1) / K;

        case "aufh_exp3pp"
            % Single-channel adaptation of AUFH-EXP3++.
            % It combines exponential loss weighting with per-channel
            % empirical-gap exploration. It deliberately ignores q_t.

            eta_t = learner.etaScale * sqrt( ...
                log(max(K, 2)) / (K * max(t, 1)));

            shiftedLoss = ...
                learner.cumLossHat - min(learner.cumLossHat);

            logWeight = -eta_t * shiftedLoss;
            logWeight = logWeight - max(logWeight);

            baseProb = exp(logWeight);
            baseProb = baseProb / sum(baseProb);

            averageLoss = ...
                learner.cumLossHat / max(t - 1, 1);

            gapEstimate = ...
                averageLoss - min(averageLoss);

            safeGap = max(gapEstimate, learner.gapFloor);

            xi_t = ...
                learner.gapExplorationC ...
                * log(max(t, 2)) ...
                ./ (max(t, 1) .* safeGap.^2);

            beta_t = 0.5 * sqrt( ...
                log(max(K, 2)) / (K * max(t, 1)));

            epsilon = min( ...
                ones(K, 1) / (2 * K), ...
                beta_t * ones(K, 1));

            epsilon = min(epsilon, xi_t);
            epsilon = max(epsilon, 0);

            totalExploration = min( ...
                sum(epsilon), ...
                learner.maxTotalExploration);

            if sum(epsilon) > 0
                epsilon = ...
                    epsilon * totalExploration / sum(epsilon);
            end

            pi_t = ...
                (1 - totalExploration) * baseProb ...
                + epsilon;

            learner.lastEta = eta_t;
            learner.lastExploration = epsilon;

            aux.baseProb = baseProb;
            aux.exploration = epsilon;
            aux.eta = eta_t;
            aux.gapEstimate = gapEstimate;

        case "ucb"
            % UCB deliberately ignores X_t and q_t.
            counts = learner.counts;
            meanReward = learner.meanReward;

            untried = find(counts == 0);

            if ~isempty(untried)

                pi_t = zeros(K, 1);
                pi_t(untried) = 1 / numel(untried);

            else

                bonus = sqrt( ...
                    learner.ucb_c ...
                    * log(max(t, 2)) ...
                    ./ counts);

                ucbScore = meanReward + bonus;

                maxScore = max(ucbScore);
                tol = 1e-12 * max(1, abs(maxScore));

                candidates = find( ...
                    abs(ucbScore - maxScore) <= tol);

                pi_t = zeros(K, 1);
                pi_t(candidates) = 1 / numel(candidates);

            end

        case "ts"
            % Thompson sampling deliberately ignores X_t and q_t.
            alpha = learner.alpha(:);
            beta = learner.beta(:);

            %% Actual TS action: one posterior draw
            thetaActual = sample_beta_variables(alpha, beta, 1);

            [~, a_t] = max(thetaActual(:, 1));
            actionAlreadySampled = true;

            %% Estimate the induced action distribution pi_t
            numMC = learner.ts_mc_samples;

            thetaMC = sample_beta_variables( ...
                alpha, beta, numMC);

            [~, winnerMC] = max(thetaMC, [], 1);

            winnerCounts = accumarray( ...
                winnerMC(:), 1, [K, 1], @sum, 0);

            pi_t = winnerCounts / numMC;

        case "exp4p"
            % Uses X_t but deliberately ignores q_t.
            [pi_t, exp4Aux] = ...
                exp4_mixture_policy(learner, X_t);

            aux.advice = exp4Aux.advice;
            aux.expertProb = exp4Aux.expertProb;
            aux.baseProb = exp4Aux.baseProb;

        case "risk_exp4"
            % Selection architecture is identical to EXP4.P.
            [pi_t, exp4Aux] = ...
                exp4_mixture_policy(learner, X_t);

            aux.advice = exp4Aux.advice;
            aux.expertProb = exp4Aux.expertProb;
            aux.baseProb = exp4Aux.baseProb;

        case { ...
                "bc_nodetect", ...
                "bc_loss_only", ...
                "bc_explore_only", ...
                "bc_detect", ...
                "bc_old_loss_only", ...
                "bc_old_detect", ...
                "bc_scale_control"}

            %% Contextual expert mixture
            %
            % The current public q_t is passed into the expert aggregator.
            % Only the NEW dual-channel mode uses it in the current round;
            % other variants receive it for common diagnostics.
            [baseProb, expertProb, advice, eta_t, riskInfo] = ...
                bc_expert_mixture( ...
                    learner, ...
                    X_t, ...
                    q_t, ...
                    t);

            %% Shared contextual nonuniform exploration
            [baseExploration, coverageScore] = ...
                bc_nonuniform_exploration( ...
                    advice, ...
                    expertProb, ...
                    learner.exploreUniformFloor);

            %% Optional prediction-aware exploration tilt
            if learner.usePredictionExploration

                [exploration, tiltWeight] = ...
                    bc_detect_exploration( ...
                        learner, ...
                        baseExploration, ...
                        q_t);

            else

                exploration = baseExploration;
                tiltWeight = ones(K, 1);

            end

            %% Exactly the same gamma schedule for all four versions
            gamma_t = min( ...
                learner.gammaMax, ...
                learner.gammaScale ...
                / sqrt(max(t, 1)));

            pi_t = ...
                (1 - gamma_t) * baseProb ...
                + gamma_t * exploration;

            %% Update diagnostics stored in learner state
            learner.lastExpertProb = expertProb;
            learner.lastEta = eta_t;
            learner.lastGamma = gamma_t;

            learner.lastCurrentExpertRiskRaw = ...
                riskInfo.rawExpertRisk;

            learner.lastCurrentExpertRiskNormalized = ...
                riskInfo.normalizedExpertRisk;

            learner.lastEffectiveExpertLoss = ...
                riskInfo.effectiveExpertLoss;

            %% Save everything required by the update and diagnostics
            aux.advice = advice;
            aux.expertProb = expertProb;
            aux.baseProb = baseProb;

            aux.baseExploration = baseExploration;
            aux.exploration = exploration;

            aux.coverageScore = coverageScore;
            aux.tiltWeight = tiltWeight;

            aux.eta = eta_t;
            aux.gamma = gamma_t;

            aux.currentExpertRiskRaw = ...
                riskInfo.rawExpertRisk;

            aux.currentExpertRiskNormalized = ...
                riskInfo.normalizedExpertRisk;

            aux.effectiveExpertLoss = ...
                riskInfo.effectiveExpertLoss;

            aux.predictionLossMode = ...
                learner.predictionLossMode;

            aux.usePredictionLoss = ...
                learner.usePredictionLoss;

            aux.useNewPredictionLoss = ...
                learner.useNewPredictionLoss;

            aux.useLegacyPredictionLoss = ...
                learner.useLegacyPredictionLoss;

            aux.usePredictionExploration = ...
                learner.usePredictionExploration;

        case { ...
                "dpact_nodetect", ...
                "dpact_loss_only", ...
                "dpact_explore_only", ...
                "dpact_detect", ...
                "dpact_safe"}

            [pi_t, dynamicAux, learner] = ...
                dynamic_pact_select(learner, X_t, q_t, t);

            aux = dynamicAux;

        case {"lc_inf", "lc_inf_pool", "lc_inf_online"}
            % LC-Tsallis-INF uses X_t but deliberately ignores q_t.
            [pi_t, baseProb, eta_t, gamma_t] = ...
                lc_policy_from_context(learner, X_t, t);

            if learner.covarianceMode == "online"
                learner.contextPool(:, :, end + 1) = X_t;
                if size(learner.contextPool, 3) ...
                        > learner.onlineBufferSize
                    learner.contextPool = learner.contextPool( ...
                        :, :, (end - learner.onlineBufferSize + 1):end);
                end
            end

            %% Recompute or reuse policy-induced covariance
            needSigmaUpdate = ...
                isempty(learner.sigmaInvCache) ...
                || (t - learner.lastSigmaUpdate ...
                    >= learner.sigmaUpdatePeriod);

            if needSigmaUpdate

                [Sigma, SigmaInv, sigmaRcond] = ...
                    compute_lc_sigma(learner, t);

                learner.sigmaCache = Sigma;
                learner.sigmaInvCache = SigmaInv;
                learner.sigmaRcond = sigmaRcond;
                learner.lastSigmaUpdate = t;

            end

            aux.baseProb = baseProb;
            aux.eta = eta_t;
            aux.gamma = gamma_t;

            aux.Sigma = learner.sigmaCache;
            aux.SigmaInv = learner.sigmaInvCache;
            aux.sigmaRcond = learner.sigmaRcond;

        otherwise
            error("Unknown learner type: %s", learner.type);
    end

    pi_t = normalize_probability(pi_t);

    if ~actionAlreadySampled
        a_t = sample_categorical(pi_t);
    end

    aux.pi_t = pi_t;
    aux.actionAlreadySampled = actionAlreadySampled;

end


function p = normalize_probability(p)

    p = p(:);

    if any(~isfinite(p)) || any(p < 0) || sum(p) <= 0
        p = ones(length(p), 1) / length(p);
    else
        p = p / sum(p);
    end

end


function idx = sample_categorical(p)

    cdf = cumsum(p);
    u = rand;

    idx = find(u <= cdf, 1, "first");

    if isempty(idx)
        idx = length(p);
    end

end


function theta = sample_beta_variables(alpha, beta, numSamples)
%SAMPLE_BETA_VARIABLES Draw independent Beta random variables.

    alpha = alpha(:);
    beta = beta(:);

    K = length(alpha);

    alphaMat = repmat(alpha, 1, numSamples);
    betaMat = repmat(beta, 1, numSamples);

    gammaA = randg(alphaMat);
    gammaB = randg(betaMat);

    denominator = max(gammaA + gammaB, realmin);

    theta = gammaA ./ denominator;

    invalid = ~isfinite(theta);

    if any(invalid, "all")
        theta(invalid) = 0.5;
    end

    assert(isequal(size(theta), [K, numSamples]), ...
        "Unexpected Beta sample matrix size.");

end
