function [predictedAction, jammed, attackAux] = ...
    sample_attack_realization(adversary, q_t, t)
%SAMPLE_ATTACK_REALIZATION Sample the hidden fixed-budget attack set.
%
% The learner observes q_t.  For non-deterministic multi-channel jammers,
% q_t is converted to marginal inclusion probabilities h_t, and dependent
% rounding samples exactly M_jam attacked channels with those marginals.

    q_t = normalize_probability(q_t);
    K = numel(q_t);

    attackAux = struct();
    attackAux.time = t;

    switch adversary.type
        case "none"
            predictedAction = sample_categorical(q_t);
            inclusionProbability = zeros(K, 1);
            jammed = zeros(K, 1);

        case "sweep"
            support = find(q_t > 0);
            jammed = zeros(K, 1);
            jammed(support) = 1;
            inclusionProbability = jammed;

            predictedAction = support(1);

        case "folpetti_ts"
            % M_jam = 1, so h_t = q_t exactly.
            inclusionProbability = ...
                attack_inclusion_probability(q_t, 1);
            jammed = sample_fixed_size_attack_set( ...
                inclusionProbability);
            predictedAction = find(jammed > 0, 1, "first");

        otherwise
            predictedAction = sample_categorical(q_t);
            inclusionProbability = ...
                attack_inclusion_probability( ...
                    q_t, adversary.M_jam);
            jammed = sample_fixed_size_attack_set( ...
                inclusionProbability);
    end

    attackAux.attackAction = predictedAction;
    attackAux.attackSet = find(jammed > 0);
    attackAux.inclusionProbability = inclusionProbability;
    attackAux.expectedAttackBudget = ...
        sum(inclusionProbability);
    attackAux.realizedAttackBudget = sum(jammed);

end


function idx = sample_categorical(probability)

    cumulative = cumsum(probability);
    randomValue = rand;

    idx = find(randomValue <= cumulative, 1, "first");

    if isempty(idx)
        idx = numel(probability);
    end

end


function probability = normalize_probability(probability)

    probability = probability(:);

    if any(~isfinite(probability)) ...
            || any(probability < 0) ...
            || sum(probability) <= 0

        probability = ...
            ones(numel(probability), 1) / numel(probability);
    else
        probability = probability / sum(probability);
    end

end
