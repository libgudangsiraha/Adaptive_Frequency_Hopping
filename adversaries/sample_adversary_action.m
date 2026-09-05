function predictedAction = sample_adversary_action(q_t)
%SAMPLE_ADVERSARY_ACTION Sample hidden prediction from q_t.

    q_t = normalize_probability(q_t);

    cdf = cumsum(q_t);
    u = rand;

    predictedAction = find(u <= cdf, 1, "first");

    if isempty(predictedAction)
        predictedAction = length(q_t);
    end

end


function p = normalize_probability(p)

    p = p(:);

    if any(~isfinite(p)) || any(p < 0) || sum(p) <= 0
        p = ones(length(p), 1) / length(p);
    else
        p = p / sum(p);
    end

end