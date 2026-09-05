function [q_t, aux] = adversary_predict( ...
    adversary, X_t, actionHistory, t)
%ADVERSARY_PREDICT Produce public prediction distribution q_t.
%
% This function is called before the learner selects A_t. It must not use
% actionHistory(t) or any future learner action.

    K = adversary.K;
    aux = struct();

    switch adversary.type

        case "none"
            q_t = ones(K, 1) / K;
            aux.publishedProb = q_t;

        case "random"
            q_t = ones(K, 1) / K;
            aux.publishedProb = q_t;

        case "sweep"
            width = adversary.sweepWidth;
            firstChannel = mod(t - 1, K) + 1;

            attackedChannels = mod( ...
                (firstChannel - 1) + (0:(width - 1)), ...
                K) + 1;

            q_t = zeros(K, 1);
            q_t(attackedChannels) = 1 / width;

            aux.sweepChannels = attackedChannels(:);
            aux.publishedProb = q_t;

        case "folpetti_ts"
            alpha = adversary.alpha(:);
            beta = adversary.beta(:);

            theta = sample_beta_variables( ...
                alpha, beta, adversary.mcSamples);

            [~, winner] = max(theta, [], 1);

            counts = accumarray( ...
                winner(:), 1, [K, 1], @sum, 0);

            q_t = counts / adversary.mcSamples;
            q_t = max(q_t, adversary.minProbability);
            q_t = q_t / sum(q_t);

            aux.posteriorWinnerCounts = counts;
            aux.publishedProb = q_t;

        case "window"
            W = adversary.window;
            alpha = adversary.alpha;

            if t <= 1
                counts = zeros(K, 1);
            else
                startIdx = max(1, t - W);
                history = actionHistory(startIdx:(t - 1));
                history = history(history >= 1 & history <= K);

                counts = accumarray( ...
                    history, 1, [K, 1], @sum, 0);
            end

            q_t = counts + alpha;
            q_t = q_t / sum(q_t);

            aux.counts = counts;
            aux.publishedProb = q_t;

        case "contextual_online"
            featureRows = adversary.featureRows;

            if max(featureRows) > size(X_t, 1)
                error( ...
                    "Contextual predictor feature row exceeds X_t.");
            end

            features = X_t(featureRows, :);

            if any(~isfinite(features), "all")
                error( ...
                    "Contextual predictor received nonfinite context.");
            end

            scores = features' * adversary.theta;
            scores = scores / adversary.temperature;
            scores = scores - max(scores);

            modelProb = exp(scores);

            if any(~isfinite(modelProb)) || sum(modelProb) <= 0
                modelProb = ones(K, 1) / K;
            else
                modelProb = modelProb / sum(modelProb);
            end

            epsilonA = adversary.uniformFloor;

            q_t = ...
                (1 - epsilonA) * modelProb ...
                + epsilonA * ones(K, 1) / K;

            q_t = q_t / sum(q_t);

            aux.features = features;
            aux.modelProb = modelProb;
            aux.publishedProb = q_t;
            aux.learningRate = ...
                adversary.eta0 / sqrt(max(t, 1));

        case "contextual_expert"
            [advice, predictorAux] = ...
                evaluate_contextual_predictor_experts( ...
                    X_t, actionHistory, t, adversary.expertBank);

            N = adversary.numExperts;

            eta_t = min( ...
                adversary.etaMax, ...
                adversary.etaScale ...
                * sqrt(2 * log(max(N, 2)) / max(t, 1)));

            logWeight = eta_t * adversary.cumExpertGain;
            logWeight = logWeight - max(logWeight);

            expertProb = exp(logWeight);

            if any(~isfinite(expertProb)) ...
                    || sum(expertProb) <= 0

                expertProb = ones(N, 1) / N;
            else
                expertProb = expertProb / sum(expertProb);
            end

            q_t = advice * expertProb;
            q_t = max(q_t, adversary.minProbability);
            q_t = q_t .^ adversary.predictionPower;
            q_t = max(q_t, adversary.minProbability);
            q_t = q_t / sum(q_t);

            aux.advice = advice;
            aux.expertProb = expertProb;
            aux.eta = eta_t;
            aux.publishedProb = q_t;
            aux.predictorAux = predictorAux;

        otherwise
            error("Unknown adversary type: %s", adversary.type);
    end

    if any(~isfinite(q_t)) || any(q_t < 0) || sum(q_t) <= 0
        q_t = ones(K, 1) / K;
    else
        q_t = q_t(:) / sum(q_t);
    end

end


function theta = sample_beta_variables(alpha, beta, numSamples)
%SAMPLE_BETA_VARIABLES Draw independent Beta random variables.

    alpha = alpha(:);
    beta = beta(:);

    alphaMatrix = repmat(alpha, 1, numSamples);
    betaMatrix = repmat(beta, 1, numSamples);

    gammaAlpha = randg(alphaMatrix);
    gammaBeta = randg(betaMatrix);

    theta = gammaAlpha ./ max(gammaAlpha + gammaBeta, realmin);

    theta(~isfinite(theta)) = 0.5;

end
