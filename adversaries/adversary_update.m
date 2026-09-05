function adversary = adversary_update( ...
    adversary, X_t, a_t, aux, t)
%ADVERSARY_UPDATE Update adversary after observing learner action A_t.
%
% This function is called only after A_t has been generated.

    %#ok<INUSD>

    switch adversary.type

        case {"none", "random", "sweep"}
            adversary.numUpdates = adversary.numUpdates + 1;

        case "folpetti_ts"
            if ~isfield(aux, "attackAction")
                error("FOLPETTI update requires aux.attackAction.");
            end

            attackedArm = aux.attackAction;

            if attackedArm < 1 || attackedArm > adversary.K
                error("Invalid FOLPETTI attack action.");
            end

            success = double(a_t == attackedArm);

            adversary.alpha(attackedArm) = ...
                adversary.alpha(attackedArm) + success;

            adversary.beta(attackedArm) = ...
                adversary.beta(attackedArm) + (1 - success);

            adversary.attackCount(attackedArm) = ...
                adversary.attackCount(attackedArm) + 1;

            adversary.successCount(attackedArm) = ...
                adversary.successCount(attackedArm) + success;

            adversary.cumulativeAttackSuccess = ...
                adversary.cumulativeAttackSuccess + success;

            adversary.lastAttackAction = attackedArm;
            adversary.numUpdates = adversary.numUpdates + 1;

        case "window"
            % No internal state update is required.
            % The window predictor reads actionHistory directly.
            
        case "contextual_online"

            features = aux.features;
            modelProb = aux.modelProb;
            qPublished = aux.publishedProb;

            eta_t = aux.learningRate;

            if a_t < 1 || a_t > adversary.K
                error("Invalid action supplied to contextual predictor.");
            end

            %% Gradient of log p(A_t | X_t)
            selectedFeature = features(:, a_t);

            expectedFeature = ...
                features * modelProb;

            gradient = ...
                selectedFeature - expectedFeature;

            %% Online gradient ascent with L2 shrinkage
            adversary.theta = ...
                (1 - eta_t * adversary.l2) ...
                * adversary.theta ...
                + eta_t * gradient;

            %% Project parameter norm for numerical stability
            thetaNorm = norm(adversary.theta);

            if thetaNorm > adversary.thetaMaxNorm

                adversary.theta = ...
                    adversary.theta ...
                    * adversary.thetaMaxNorm ...
                    / thetaNorm;

                thetaNorm = adversary.thetaMaxNorm;

            end

            %% Prediction log-loss diagnostic
            logLoss = ...
                -log(max(qPublished(a_t), 1e-12));

            adversary.lastLogLoss = logLoss;

            adversary.cumulativeLogLoss = ...
                adversary.cumulativeLogLoss + logLoss;

            adversary.numUpdates = ...
                adversary.numUpdates + 1;

            adversary.maxThetaNorm = max( ...
                adversary.maxThetaNorm, thetaNorm);
            
      case "contextual_expert"

            K = adversary.K;

            if a_t < 1 || a_t > K
                error( ...
                    "Invalid action supplied to contextual expert predictor.");
            end

            advice = aux.advice;
            expertProb = aux.expertProb;
            qPublished = aux.publishedProb;

            if size(advice, 1) ~= K ...
                    || size(advice, 2) ~= adversary.numExperts

                error( ...
                    "Invalid predictor expert advice matrix.");

            end

            %% Full-information gain of every predictor expert
            %
            % Expert j receives:
            %   sigma_j(A_t | X_t,H_{t-1})
            expertGain = advice(a_t, :)';

            if any(~isfinite(expertGain)) ...
                    || any(expertGain < 0) ...
                    || any(expertGain > 1)

                error( ...
                    "Predictor expert gain is invalid.");

            end

            %% Published predictor gain
            mixtureGain = qPublished(a_t);

            %% Update cumulative gains
            adversary.cumExpertGain = ...
                adversary.cumExpertGain ...
                + expertGain;

            adversary.cumulativeMixtureGain = ...
                adversary.cumulativeMixtureGain ...
                + mixtureGain;

            adversary.cumulativeLogLoss = ...
                adversary.cumulativeLogLoss ...
                - log(max(mixtureGain, 1e-12));

            %% Predictor regret relative to best fixed expert
            [bestGain, bestIndex] = ...
                max(adversary.cumExpertGain);

            adversary.predictorRegret = ...
                bestGain ...
                - adversary.cumulativeMixtureGain;

            adversary.bestExpertIndex = bestIndex;

            %% Diagnostics
            adversary.lastExpertProb = expertProb;
            adversary.lastEta = aux.eta;

            adversary.maxExpertWeight = max( ...
                adversary.maxExpertWeight, ...
                max(expertProb));

            adversary.numUpdates = ...
                adversary.numUpdates + 1;

        otherwise
            error("Unknown adversary type: %s", adversary.type);
    end

end