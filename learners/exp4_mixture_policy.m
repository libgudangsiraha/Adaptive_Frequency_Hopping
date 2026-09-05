function [pi_t, aux] = exp4_mixture_policy(learner, X_t)
%EXP4_MIXTURE_POLICY Common expert-mixture policy for EXP4-type learners.

    K = learner.K;

    %% Contextual expert advice: K x N
    advice = evaluate_policy_experts( ...
        X_t, learner.expertBank);

    %% Stable expert-weight normalization
    logW = learner.logWeights(:);
    shiftedLogW = logW - max(logW);

    expertProb = exp(shiftedLogW);
    expertProb = expertProb / sum(expertProb);

    %% Expert-mixture recommendation
    baseProb = advice * expertProb;

    %% Uniform exploration with minimum arm probability
    pMin = learner.pMin;

    pi_t = ...
        (1 - K * pMin) * baseProb ...
        + pMin * ones(K, 1);

    if any(~isfinite(pi_t)) ...
            || any(pi_t < 0) ...
            || sum(pi_t) <= 0

        pi_t = ones(K, 1) / K;
    else
        pi_t = pi_t / sum(pi_t);
    end

    %% Information needed by the update
    aux.advice = advice;
    aux.expertProb = expertProb;
    aux.baseProb = baseProb;

end