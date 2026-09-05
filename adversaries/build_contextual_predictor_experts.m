function bank = build_contextual_predictor_experts(cfg)
%BUILD_CONTEXTUAL_PREDICTOR_EXPERTS
% Build a finite contextual predictor expert class.
%
% Expert families:
%   1. uniform;
%   2. context-only linear-softmax;
%   3. history-only;
%   4. context-history hybrid.

    featureDim = numel(cfg.featureRows);

    if featureDim ~= 3
        error( ...
            "Current predictor bank expects three context features.");
    end

    expertType = strings(0, 1);
    expertName = strings(0, 1);

    contextWeights = zeros(featureDim, 0);
    temperature = zeros(0, 1);
    historyWindow = zeros(0, 1);
    historyMix = zeros(0, 1);

    %% Helper for appending one expert
    function append_expert( ...
            typeValue, ...
            nameValue, ...
            weightValue, ...
            temperatureValue, ...
            windowValue, ...
            mixValue)

        expertType(end + 1, 1) = string(typeValue);
        expertName(end + 1, 1) = string(nameValue);

        contextWeights(:, end + 1) = weightValue(:);

        temperature(end + 1, 1) = ...
            temperatureValue;

        historyWindow(end + 1, 1) = ...
            windowValue;

        historyMix(end + 1, 1) = ...
            mixValue;

    end

    %% 1. Uniform expert
    append_expert( ...
        "uniform", ...
        "predictor_uniform", ...
        zeros(featureDim, 1), ...
        1.0, ...
        0, ...
        0);

    %% 2. Context-only experts
    level = cfg.contextWeightLevel;

    for a = 0:level
        for b = 0:(level - a)

            c = level - a - b;

            weight = [a; b; c] / level;

            for tau = cfg.contextTemperatures

                nameValue = sprintf( ...
                    "context_s%.2f_d%.2f_a%.2f_tau%.2f", ...
                    weight(1), ...
                    weight(2), ...
                    weight(3), ...
                    tau);

                append_expert( ...
                    "context", ...
                    nameValue, ...
                    weight, ...
                    tau, ...
                    0, ...
                    0);

            end
        end
    end

    %% 3. History-only experts
    for W = cfg.historyWindows
        for tau = cfg.historyTemperatures

            windowLabel = local_window_label(W);

            nameValue = sprintf( ...
                "history_W%s_tau%.2f", ...
                windowLabel, ...
                tau);

            append_expert( ...
                "history", ...
                nameValue, ...
                zeros(featureDim, 1), ...
                tau, ...
                W, ...
                1.0);

        end
    end

    %% 4. Context-history hybrid experts
    hybridWeights = ...
        cfg.hybridContextWeights;

    for weightIndex = 1:size(hybridWeights, 2)

        weight = hybridWeights(:, weightIndex);

        for W = cfg.hybridHistoryWindows
            for beta = cfg.hybridMixes
                for tau = cfg.hybridTemperatures

                    windowLabel = ...
                        local_window_label(W);

                    nameValue = sprintf( ...
                        "hybrid_s%.2f_d%.2f_a%.2f_W%s_b%.2f_tau%.2f", ...
                        weight(1), ...
                        weight(2), ...
                        weight(3), ...
                        windowLabel, ...
                        beta, ...
                        tau);

                    append_expert( ...
                        "hybrid", ...
                        nameValue, ...
                        weight, ...
                        tau, ...
                        W, ...
                        beta);

                end
            end
        end
    end

    %% Output bank
    bank.K = cfg.K;
    bank.featureRows = cfg.featureRows;
    bank.historyAlpha = cfg.historyAlpha;

    bank.type = expertType;
    bank.name = expertName;

    bank.contextWeights = contextWeights;
    bank.temperature = temperature;
    bank.historyWindow = historyWindow;
    bank.historyMix = historyMix;

    bank.numExperts = numel(expertType);

end


function label = local_window_label(W)

    if isinf(W)
        label = "all";
    else
        label = sprintf("%d", round(W));
    end

end