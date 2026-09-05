function learner = learner_update( ...
    learner, X_t, feedback, aux, t, cfg)
%LEARNER_UPDATE Update communication learner after observing feedback.
%
% feedback fields:
%   action  - selected arm A_t
%   reward  - observed communication reward
%   pi      - action distribution used at time t
%   q       - public prediction-risk distribution

    %#ok<INUSD>

    switch learner.type

        case "exp3"
            a_t = feedback.action;
            reward_t = feedback.reward;
            pi_t = feedback.pi;

            K = learner.K;
            gamma = learner.gamma;

            pSelected = max(pi_t(a_t), 1e-12);

            estimatedReward = reward_t / pSelected;

            learner.logWeights(a_t) = ...
                learner.logWeights(a_t) ...
                + gamma * estimatedReward / K;

            learner.logWeights = ...
                learner.logWeights - max(learner.logWeights);

        case "aufh_exp3pp"
            a_t = feedback.action;
            reward_t = min(max(feedback.reward, 0), 1);
            pi_t = feedback.pi(:);

            observedLoss = 1 - reward_t;
            selectedProbability = max(pi_t(a_t), 1e-12);

            learner.cumLossHat(a_t) = ...
                learner.cumLossHat(a_t) ...
                + observedLoss / selectedProbability;

            learner.counts(a_t) = learner.counts(a_t) + 1;
            learner.numUpdates = learner.numUpdates + 1;

        case "ucb"
            a_t = feedback.action;
            reward_t = feedback.reward;

            learner.counts(a_t) = learner.counts(a_t) + 1;
            n = learner.counts(a_t);

            learner.meanReward(a_t) = ...
                learner.meanReward(a_t) ...
                + (reward_t - learner.meanReward(a_t)) / n;

        case "ts"
            a_t = feedback.action;

            reward_t = min(max(feedback.reward, 0), 1);

            learner.alpha(a_t) = ...
                learner.alpha(a_t) + reward_t;

            learner.beta(a_t) = ...
                learner.beta(a_t) + (1 - reward_t);

            learner.counts(a_t) = ...
                learner.counts(a_t) + 1;

        case { ...
                "bc_nodetect", ...
                "bc_loss_only", ...
                "bc_explore_only", ...
                "bc_detect", ...
                "bc_old_loss_only", ...
                "bc_old_detect", ...
                "bc_scale_control"}

            a_t = feedback.action;
            reward_t = min(max(feedback.reward, 0), 1);

            pi_t = feedback.pi(:);
            q_t = feedback.q(:);
            advice = aux.advice;

            K = learner.K;
            N = learner.numExperts;

            if ~isequal(size(advice), [K, N])
                error( ...
                    "B+C received an invalid partition advice matrix.");
            end

            if numel(pi_t) ~= K
                error("B+C received an invalid pi_t.");
            end

            %% Normalize q_t and compute exact current expert risk
            [expectedExpertRisk, normalizedExpertRisk, q_t] = ...
                bc_expert_prediction_risk(advice, q_t);

            %% Ensure selection and update used the same current risk signal
            if isfield(aux, "currentExpertRiskRaw")

                consistencyError = max(abs( ...
                    aux.currentExpertRiskRaw(:) ...
                    - expectedExpertRisk));

                if consistencyError > 1e-10
                    error( ...
                        "Selection/update expert-risk mismatch.");
                end

            end

            if isfield(aux, "currentExpertRiskNormalized")

                consistencyError = max(abs( ...
                    aux.currentExpertRiskNormalized(:) ...
                    - normalizedExpertRisk));

                if consistencyError > 1e-10
                    error( ...
                        "Selection/update normalized-risk mismatch.");
                end

            end

            %% Importance-weighted communication-loss estimator
            observedLoss = 1 - reward_t;

            communicationLossHat = zeros(K, 1);

            selectedProbability = ...
                max(pi_t(a_t), 1e-12);

            communicationLossHat(a_t) = ...
                observedLoss / selectedProbability;

            estimatedCommExpertLoss = ...
                advice' * communicationLossHat;

            if any(~isfinite(estimatedCommExpertLoss))
                error( ...
                    "B+C communication expert loss became nonfinite.");
            end

            %% Update the raw communication-loss channel
            learner.cumCommExpertLoss = ...
                learner.cumCommExpertLoss ...
                + estimatedCommExpertLoss;

            %% Update the full-information prediction-risk channel
            %
            % In new mode, g_t was already used in the current selection.
            % It is stored now so that the next round has Q_t.
            learner.cumPredictionExpertRisk = ...
                learner.cumPredictionExpertRisk ...
                + normalizedExpertRisk;

            %% Legacy objective, retained only for controlled ablations
            mode = string(learner.predictionLossMode);
            legacyIncrement = [];

            if mode == "legacy_normalized"

                lambda = learner.detectLambda;

                legacyArmLossHat = ...
                    (communicationLossHat + lambda * q_t) ...
                    / (1 + lambda);

                legacyIncrement = ...
                    advice' * legacyArmLossHat;

                learner.cumLegacyExpertLoss = ...
                    learner.cumLegacyExpertLoss ...
                    + legacyIncrement;

            elseif mode == "scale_control"

                lambda = learner.detectLambda;

                legacyArmLossHat = ...
                    communicationLossHat ...
                    / (1 + lambda);

                legacyIncrement = ...
                    advice' * legacyArmLossHat;

                learner.cumLegacyExpertLoss = ...
                    learner.cumLegacyExpertLoss ...
                    + legacyIncrement;

            end

            %% Backward-compatible cumulative-loss alias
            if ismember( ...
                    mode, ...
                    ["legacy_normalized", "scale_control"])

                learner.cumExpertLoss = ...
                    learner.cumLegacyExpertLoss;
            else
                learner.cumExpertLoss = ...
                    learner.cumCommExpertLoss;
            end

            %% Raw expected q-risk diagnostics for every expert
            learner.cumulativeExpectedExpertRisk = ...
                learner.cumulativeExpectedExpertRisk ...
                + expectedExpertRisk;

            %% Diagnostics
            learner.lastCurrentExpertRiskRaw = ...
                expectedExpertRisk;

            learner.lastCurrentExpertRiskNormalized = ...
                normalizedExpertRisk;

            learner.maxEstimatedCommExpertLoss = max( ...
                learner.maxEstimatedCommExpertLoss, ...
                max(estimatedCommExpertLoss));

            learner.maxEstimatedExpertLoss = max( ...
                learner.maxEstimatedExpertLoss, ...
                max(estimatedCommExpertLoss));

            learner.maxAbsPredictionRiskSignal = max( ...
                learner.maxAbsPredictionRiskSignal, ...
                max(abs(normalizedExpertRisk)));

            if ~isempty(legacyIncrement)

                learner.maxLegacyEstimatedExpertLoss = max( ...
                    learner.maxLegacyEstimatedExpertLoss, ...
                    max(legacyIncrement));

            end

            learner.numUpdates = ...
                learner.numUpdates + 1;

        case { ...
                "dpact_nodetect", ...
                "dpact_loss_only", ...
                "dpact_explore_only", ...
                "dpact_detect", ...
                "dpact_safe"}

            learner = dynamic_pact_update( ...
                learner, X_t, feedback, aux, t);

        case "risk_exp4"
            a_t = feedback.action;

            reward_t = min(max(feedback.reward, 0), 1);

            pi_t = feedback.pi(:);
            q_t = feedback.q(:);

            advice = aux.advice;

            K = learner.K;
            N = learner.numExperts;
            lambda = learner.detectLambda;

            if ~isequal(size(advice), [K, N])
                error( ...
                    "Risk-aware EXP4 received an invalid advice matrix.");
            end

            if numel(q_t) ~= K
                error( ...
                    "Risk-aware EXP4 received an invalid q_t.");
            end

            %% Bandit estimate of raw communication reward
            rewardHat = zeros(K, 1);

            selectedProbability = ...
                max(pi_t(a_t), 1e-12);

            rewardHat(a_t) = ...
                reward_t / selectedProbability;

            %% Mixed effective-utility estimator
            utilityHat = ...
                (rewardHat + lambda * (1 - q_t)) ...
                / (1 + lambda);

            %% Estimated utility of each policy expert
            estimatedExpertUtility = ...
                advice' * utilityHat;

            %% Expected prediction risk of each expert
            expectedExpertRisk = ...
                advice' * q_t;

            %% Variance proxy for the bandit reward component
            varianceProxy = sum( ...
                bsxfun( ...
                    @rdivide, ...
                    advice, ...
                    max(pi_t, 1e-12)), ...
                1)';

            confidenceCorrection = ...
                learner.confidenceScale ...
                .* varianceProxy ...
                / (1 + lambda);

            updateIncrement = ...
                (learner.pMin / 2) ...
                .* (estimatedExpertUtility ...
                + confidenceCorrection);

            learner.logWeights = ...
                learner.logWeights + updateIncrement;

            learner.logWeights = ...
                learner.logWeights ...
                - max(learner.logWeights);

            %% Diagnostics
            learner.cumulativeEstimatedUtility = ...
                learner.cumulativeEstimatedUtility ...
                + estimatedExpertUtility;

            learner.cumulativeExpectedRisk = ...
                learner.cumulativeExpectedRisk ...
                + expectedExpertRisk;

            learner.cumulativeVarianceProxy = ...
                learner.cumulativeVarianceProxy ...
                + varianceProxy;

        case "exp4p"
            a_t = feedback.action;

            reward_t = min(max(feedback.reward, 0), 1);

            pi_t = feedback.pi(:);
            advice = aux.advice;

            K = learner.K;
            N = learner.numExperts;

            if ~isequal(size(advice), [K, N])
                error("EXP4.P received an invalid advice matrix.");
            end

            %% Importance-weighted arm reward estimate
            rewardHat = zeros(K, 1);

            selectedProbability = max(pi_t(a_t), 1e-12);

            rewardHat(a_t) = reward_t / selectedProbability;

            %% Estimated reward of every expert
            estimatedExpertReward = advice' * rewardHat;

            %% Expert variance proxy
            varianceProxy = sum( ...
                bsxfun(@rdivide, advice, max(pi_t, 1e-12)), ...
                1)';

            %% Original EXP4.P weight update
            updateIncrement = ...
                (learner.pMin / 2) ...
                .* (estimatedExpertReward ...
                + learner.confidenceScale .* varianceProxy);

            learner.logWeights = ...
                learner.logWeights + updateIncrement;

            learner.logWeights = ...
                learner.logWeights - max(learner.logWeights);

            %% Diagnostics
            learner.cumulativeEstimatedReward = ...
                learner.cumulativeEstimatedReward ...
                + estimatedExpertReward;

            learner.cumulativeVarianceProxy = ...
                learner.cumulativeVarianceProxy ...
                + varianceProxy;

        case {"lc_inf", "lc_inf_pool", "lc_inf_online"}
            a_t = feedback.action;

            observedLoss = ...
                1 - min(max(feedback.reward, 0), 1);

            phiSelected = X_t(:, a_t);

            SigmaInv = aux.SigmaInv;

            %% Regression coefficient estimator
            thetaHat = ...
                SigmaInv * phiSelected * observedLoss;

            if any(~isfinite(thetaHat))
                error("LC theta estimator became nonfinite.");
            end

            learner.cumThetaHat = ...
                learner.cumThetaHat + thetaHat;

            %% Diagnostics
            learner.lastThetaHat = thetaHat;

            thetaHatNorm = norm(thetaHat);

            learner.maxThetaHatNorm = max( ...
                learner.maxThetaHatNorm, thetaHatNorm);

            learner.numUpdates = learner.numUpdates + 1;

        otherwise
            error("Unknown learner type: %s", learner.type);
    end

end
