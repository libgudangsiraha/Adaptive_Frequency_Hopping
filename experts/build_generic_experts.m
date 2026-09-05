function expertBank = build_generic_experts(expertCfg)
%BUILD_GENERIC_EXPERTS Construct fixed linear-softmax policy experts.
%
% Each nonuniform expert has:
%   - a fixed feature-weight vector;
%   - a fixed softmax temperature.
%
% The first expert is uniform when includeUniform = true.

    G = expertCfg.gridLevel;
    temperatures = expertCfg.temperatures(:)';
    numFeatures = numel(expertCfg.featureRows);

    if numFeatures ~= 3
        error("Current grid construction requires exactly 3 features.");
    end

    if G < 1 || G ~= round(G)
        error("gridLevel must be a positive integer.");
    end

    %% Generate all nonnegative triples summing to G
    baseWeights = [];

    for n1 = 0:G
        for n2 = 0:(G - n1)

            n3 = G - n1 - n2;

            w = [n1; n2; n3] / G;
            baseWeights(:, end + 1) = w; %#ok<AGROW>

        end
    end

    numBaseWeights = size(baseWeights, 2);
    numTemperatures = numel(temperatures);
    numContextualExperts = numBaseWeights * numTemperatures;

    if expertCfg.includeUniform
        offset = 1;
        numExperts = numContextualExperts + 1;
    else
        offset = 0;
        numExperts = numContextualExperts;
    end

    %% Allocate bank
    expertBank.numExperts = numExperts;
    expertBank.K = expertCfg.K;
    expertBank.featureRows = expertCfg.featureRows;
    expertBank.featureNames = expertCfg.featureNames;
    expertBank.normalizePerRound = expertCfg.normalizePerRound;

    expertBank.weights = NaN(numFeatures, numExperts);
    expertBank.temperature = NaN(1, numExperts);
    expertBank.isUniform = false(1, numExperts);
    expertBank.names = strings(1, numExperts);

    %% Uniform expert
    if expertCfg.includeUniform
        expertBank.isUniform(1) = true;
        expertBank.names(1) = "uniform";
    end

    %% Linear-softmax contextual experts
    idx = offset;

    for tau = temperatures
        for j = 1:numBaseWeights

            idx = idx + 1;

            w = baseWeights(:, j);

            expertBank.weights(:, idx) = w;
            expertBank.temperature(idx) = tau;

            expertBank.names(idx) = sprintf( ...
                "lin_s%.2f_d%.2f_a%.2f_tau%.2f", ...
                w(1), w(2), w(3), tau);

        end
    end

    if idx ~= numExperts
        error("Expert-bank construction produced inconsistent size.");
    end

end