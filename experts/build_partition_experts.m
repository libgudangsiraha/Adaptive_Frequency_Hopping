function expertBank = build_partition_experts(expertCfg)
%BUILD_PARTITION_EXPERTS Construct multi-scale arm-wise partition experts.
%
% Each expert contains:
%   - one partition resolution;
%   - one nonnegative feature-weight vector;
%   - one softmax temperature.

    G = expertCfg.gridLevel;

    numFeatures = numel(expertCfg.featureRows);
    numScales = size(expertCfg.partitionScales, 1);
    temperatures = expertCfg.temperatures(:)';

    if numFeatures ~= 3
        error("Current implementation requires exactly three features.");
    end

    if size(expertCfg.partitionScales, 2) ~= numFeatures
        error("Partition-scale dimension is inconsistent.");
    end

    if numel(expertCfg.binaryFeatureMask) ~= numFeatures
        error("binaryFeatureMask has an invalid size.");
    end

    %% Generate all nonnegative weight triples summing to G
    baseWeights = [];

    for n1 = 0:G
        for n2 = 0:(G - n1)

            n3 = G - n1 - n2;

            baseWeights(:, end + 1) = ...
                [n1; n2; n3] / G; %#ok<AGROW>

        end
    end

    numBaseWeights = size(baseWeights, 2);
    numTemperatures = numel(temperatures);

    numPartitionExperts = ...
        numScales * numBaseWeights * numTemperatures;

    if expertCfg.includeUniform
        offset = 1;
        numExperts = numPartitionExperts + 1;
    else
        offset = 0;
        numExperts = numPartitionExperts;
    end

    %% Allocate expert bank
    expertBank.K = expertCfg.K;
    expertBank.numExperts = numExperts;

    expertBank.featureRows = expertCfg.featureRows;
    expertBank.featureNames = expertCfg.featureNames;

    expertBank.featureMin = expertCfg.featureMin(:);
    expertBank.featureMax = expertCfg.featureMax(:);
    expertBank.binaryFeatureMask = ...
        logical(expertCfg.binaryFeatureMask(:));

    expertBank.partitionScales = ...
        expertCfg.partitionScales;

    expertBank.scaleNames = ...
        expertCfg.scaleNames;

    expertBank.weights = NaN(numFeatures, numExperts);
    expertBank.temperature = NaN(1, numExperts);

    expertBank.scaleIndex = NaN(1, numExperts);
    expertBank.binCounts = NaN(numFeatures, numExperts);

    expertBank.isUniform = false(1, numExperts);
    expertBank.names = strings(1, numExperts);

    %% Uniform expert
    if expertCfg.includeUniform
        expertBank.isUniform(1) = true;
        expertBank.names(1) = "uniform";
    end

    %% Partition-induced contextual experts
    idx = offset;

    for scaleIdx = 1:numScales

        bins = expertCfg.partitionScales(scaleIdx, :)';
        scaleName = expertCfg.scaleNames(scaleIdx);

        for tau = temperatures

            for j = 1:numBaseWeights

                idx = idx + 1;

                w = baseWeights(:, j);

                expertBank.weights(:, idx) = w;
                expertBank.temperature(idx) = tau;

                expertBank.scaleIndex(idx) = scaleIdx;
                expertBank.binCounts(:, idx) = bins;

                expertBank.names(idx) = sprintf( ...
                    "part_%s_s%.2f_d%.2f_a%.2f_tau%.2f", ...
                    scaleName, ...
                    w(1), w(2), w(3), tau);

            end
        end

    end

    if idx ~= numExperts
        error("Partition expert-bank size is inconsistent.");
    end

end