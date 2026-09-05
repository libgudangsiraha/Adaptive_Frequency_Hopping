function jammed = sample_attack_set(q_t, M_jam)
%SAMPLE_ATTACK_SET Sample M_jam distinct attacked arms from q_t.
%
% Output:
%   jammed - K x 1 binary vector

    q_t = q_t(:);
    K = length(q_t);
    M = min(max(round(M_jam), 0), K);

    jammed = zeros(K, 1);

    if M == 0
        return;
    end

    availableIdx = (1:K)';
    weights = q_t;

    for m = 1:M

        weights = normalize_probability(weights);
        localIdx = sample_index(weights);

        selectedArm = availableIdx(localIdx);
        jammed(selectedArm) = 1;

        % Remove the selected arm for sampling without replacement.
        availableIdx(localIdx) = [];
        weights(localIdx) = [];
    end

end


function idx = sample_index(p)

    cdf = cumsum(p);
    u = rand;

    idx = find(u <= cdf, 1, "first");

    if isempty(idx)
        idx = length(p);
    end

end


function p = normalize_probability(p)

    p = p(:);

    if isempty(p)
        return;
    end

    if any(~isfinite(p)) || any(p < 0) || sum(p) <= 0
        p = ones(length(p), 1) / length(p);
    else
        p = p / sum(p);
    end

end