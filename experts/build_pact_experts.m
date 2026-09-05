function bank = build_pact_experts(expertCfg)
%BUILD_PACT_EXPERTS Build partition-only, linear-only, or hybrid experts.

    mode = lower(string(expertCfg.mode));
    partitionBank = build_partition_experts(expertCfg.partitionCfg);

    linearWeights = simplex_weights(expertCfg.linearGridLevel);
    linearTemperatures = expertCfg.linearTemperatures(:)';

    [weightIndex, temperatureIndex] = ndgrid( ...
        1:size(linearWeights, 2), ...
        1:numel(linearTemperatures));

    linearWeightMatrix = ...
        linearWeights(:, weightIndex(:));
    linearTemperatureVector = ...
        linearTemperatures(temperatureIndex(:));

    switch mode
        case "partition"
            numLinear = 0;
        case "linear"
            numLinear = size(linearWeightMatrix, 2);
        case "hybrid"
            numLinear = size(linearWeightMatrix, 2);
        otherwise
            error("Unknown PACT expert-bank mode: %s", mode);
    end

    bank.bankType = "pact";
    bank.mode = mode;
    bank.K = expertCfg.K;
    bank.partitionBank = partitionBank;
    bank.linearFeatureRows = expertCfg.linearFeatureRows;
    bank.linearFeatureNames = expertCfg.linearFeatureNames;
    bank.linearWeights = linearWeightMatrix(:, 1:numLinear);
    bank.linearTemperature = linearTemperatureVector(1:numLinear);

    if mode == "linear"
        bank.partitionIndices = zeros(1, 0);
        bank.linearIndices = 1:numLinear;
        bank.numExperts = numLinear;
        bank.isUniform = false(1, bank.numExperts);
        bank.scaleIndex = NaN(1, bank.numExperts);
        bank.familyIndex = 2 * ones(1, bank.numExperts);
        bank.names = strings(1, bank.numExperts);
    else
        bank.partitionIndices = 1:partitionBank.numExperts;
        bank.linearIndices = ...
            partitionBank.numExperts + (1:numLinear);
        bank.numExperts = partitionBank.numExperts + numLinear;
        bank.isUniform = [ ...
            partitionBank.isUniform, false(1, numLinear)];
        bank.scaleIndex = [ ...
            partitionBank.scaleIndex, NaN(1, numLinear)];
        bank.familyIndex = [ ...
            ones(1, partitionBank.numExperts), ...
            2 * ones(1, numLinear)];
        bank.names = [partitionBank.names, strings(1, numLinear)];
    end

    for index = 1:numLinear
        w = bank.linearWeights(:, index);
        tau = bank.linearTemperature(index);
        bank.names(bank.linearIndices(index)) = sprintf( ...
            "linear_s%.2f_d%.2f_a%.2f_tau%.2f", ...
            w(1), w(2), w(3), tau);
    end

end


function weights = simplex_weights(level)

    if level < 1 || level ~= round(level)
        error("linearGridLevel must be a positive integer.");
    end

    weights = zeros(3, (level + 1) * (level + 2) / 2);
    index = 0;

    for n1 = 0:level
        for n2 = 0:(level - n1)
            n3 = level - n1 - n2;
            index = index + 1;
            weights(:, index) = [n1; n2; n3] ./ level;
        end
    end

end
