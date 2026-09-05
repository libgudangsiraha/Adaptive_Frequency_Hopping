function advice = evaluate_pact_experts(X_t, bank)
%EVALUATE_PACT_EXPERTS Evaluate hybrid PACT expert advice.

    K = bank.K;
    advice = zeros(K, bank.numExperts);

    if ~isempty(bank.partitionIndices)
        partitionAdvice = evaluate_partition_experts( ...
            X_t, bank.partitionBank);
        advice(:, bank.partitionIndices) = partitionAdvice;
    end

    if ~isempty(bank.linearIndices)
        features = X_t(bank.linearFeatureRows, :);
        features = min(max(features, 0), 1);

        scores = features' * bank.linearWeights;
        temperatures = max(bank.linearTemperature, 1e-8);
        scaled = scores ./ temperatures;
        scaled = scaled - max(scaled, [], 1);

        probability = exp(scaled);
        denominator = sum(probability, 1);
        invalid = ~isfinite(denominator) | denominator <= 0;
        denominator(invalid) = 1;
        probability = probability ./ denominator;
        probability(:, invalid) = 1 / K;

        advice(:, bank.linearIndices) = probability;
    end

    if any(~isfinite(advice), "all") ...
            || any(advice < 0, "all")
        error("Invalid PACT expert advice.");
    end

    advice = advice ./ sum(advice, 1);

end
