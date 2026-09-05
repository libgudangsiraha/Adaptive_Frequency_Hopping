function effectiveExpertLoss = ...
    bc_effective_expert_loss( ...
        learner, currentNormalizedExpertRisk)
%BC_EFFECTIVE_EXPERT_LOSS Objective passed to Tsallis-FTRL.
%
% New dual-channel current-round mode:
%
%   S_t =
%       L_{t-1}^{comm}
%       + beta * [Q_{t-1} + kappa * g_t].
%
% Legacy mode:
%   use the already accumulated normalized mixed objective.
%
% No-loss mode:
%   use communication loss only.

    currentNormalizedExpertRisk = ...
        currentNormalizedExpertRisk(:);

    N = learner.numExperts;

    if numel(currentNormalizedExpertRisk) ~= N
        error( ...
            "Current expert-risk signal has an invalid dimension.");
    end

    mode = string(learner.predictionLossMode);

    switch mode

        case "dual_current"

            if ~isfinite(learner.detectBeta) ...
                    || learner.detectBeta < 0

                error("detectBeta must be finite and nonnegative.");
            end

            if ~isfinite(learner.currentRiskWeight) ...
                    || learner.currentRiskWeight < 0

                error( ...
                    "currentRiskWeight must be finite and nonnegative.");
            end

            effectiveExpertLoss = ...
                learner.cumCommExpertLoss ...
                + learner.detectBeta ...
                .* ( ...
                    learner.cumPredictionExpertRisk ...
                    + learner.currentRiskWeight ...
                    .* currentNormalizedExpertRisk);

        case {"legacy_normalized", "scale_control"}

            effectiveExpertLoss = ...
                learner.cumLegacyExpertLoss;

        case "none"

            effectiveExpertLoss = ...
                learner.cumCommExpertLoss;

        otherwise
            error( ...
                "Unknown B+C prediction-loss mode: %s", ...
                mode);
    end

    if any(~isfinite(effectiveExpertLoss))
        error("Effective B+C expert loss became nonfinite.");
    end

end
