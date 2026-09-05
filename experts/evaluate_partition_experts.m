function advice = evaluate_partition_experts(X_t, expertBank)
%EVALUATE_PARTITION_EXPERTS Vectorized multi-scale partition evaluation.
%
% v1 quantized the same context separately for every expert. v2 computes
% each scale once and evaluates all weight/temperature combinations in a
% matrix operation.

    K = expertBank.K;
    N = expertBank.numExperts;

    if size(X_t, 2) ~= K
        error("X_t arm count does not match the expert bank.");
    end

    rawFeatures = X_t(expertBank.featureRows, :);

    if any(~isfinite(rawFeatures), "all")
        error("Partition expert context contains nonfinite values.");
    end

    advice = zeros(K, N);

    uniformIndex = find(expertBank.isUniform);
    if ~isempty(uniformIndex)
        advice(:, uniformIndex) = 1 / K;
    end

    scaleValues = unique( ...
        expertBank.scaleIndex(isfinite(expertBank.scaleIndex)));

    for scaleIndex = scaleValues(:)'

        expertIndex = find(expertBank.scaleIndex == scaleIndex);
        bins = expertBank.binCounts(:, expertIndex(1));

        partitionFeatures = quantize_local_context( ...
            rawFeatures, bins, ...
            expertBank.featureMin, ...
            expertBank.featureMax, ...
            expertBank.binaryFeatureMask);

        scores = partitionFeatures' ...
            * expertBank.weights(:, expertIndex);

        temperatures = max( ...
            expertBank.temperature(expertIndex), 1e-8);

        scaled = scores ./ temperatures;
        scaled = scaled - max(scaled, [], 1);

        probability = exp(scaled);
        denominator = sum(probability, 1);

        invalid = ~isfinite(denominator) | denominator <= 0;
        denominator(invalid) = 1;
        probability = probability ./ denominator;
        probability(:, invalid) = 1 / K;

        advice(:, expertIndex) = probability;
    end

    columnSums = sum(advice, 1);

    if any(~isfinite(advice), "all") ...
            || any(advice < 0, "all") ...
            || any(columnSums <= 0)
        error("Invalid partition expert advice matrix.");
    end

    advice = advice ./ columnSums;

end


function quantized = quantize_local_context( ...
    rawFeatures, binCounts, featureMin, featureMax, binaryMask)

    [numFeatures, K] = size(rawFeatures);
    quantized = zeros(numFeatures, K);

    for featureIndex = 1:numFeatures

        values = rawFeatures(featureIndex, :);

        if binaryMask(featureIndex)
            quantized(featureIndex, :) = double(values >= 0.5);
            continue;
        end

        lowerBound = featureMin(featureIndex);
        upperBound = featureMax(featureIndex);
        featureRange = upperBound - lowerBound;

        normalized = ...
            (values - lowerBound) ./ featureRange;
        normalized = min(max(normalized, 0), 1);

        numBins = binCounts(featureIndex);
        binIndex = floor(normalized .* numBins) + 1;
        binIndex = min(binIndex, numBins);

        quantized(featureIndex, :) = ...
            (binIndex - 0.5) ./ numBins;
    end

end
