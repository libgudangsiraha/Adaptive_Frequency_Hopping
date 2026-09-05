function [rawExpertRisk, normalizedExpertRisk, q_t] = ...
    bc_expert_prediction_risk(advice, q_t)
%BC_EXPERT_PREDICTION_RISK Expert-level risk induced by public q_t.
%
% rawExpertRisk(i):
%   rho_i(X_t)' * q_t
%
% normalizedExpertRisk(i):
%   [rawExpertRisk(i) - 1/K] / [1 - 1/K]
%
% The subtraction of 1/K is common across experts and therefore does not
% change their ordering. The normalization places the signal in
% [-1/(K-1), 1] when K > 1.

    [K, ~] = size(advice);

    q_t = q_t(:);

    if numel(q_t) ~= K
        error("B+C received an invalid q_t dimension.");
    end

    if any(~isfinite(q_t)) ...
            || any(q_t < 0) ...
            || sum(q_t) <= 0

        q_t = ones(K, 1) / K;
    else
        q_t = q_t / sum(q_t);
    end

    if any(~isfinite(advice), "all") ...
            || any(advice < 0, "all")

        error("B+C advice contains invalid probabilities.");
    end

    rawExpertRisk = advice' * q_t;

    % Protect against negligible floating-point excursions.
    rawExpertRisk = min(max(rawExpertRisk, 0), 1);

    if K <= 1
        normalizedExpertRisk = ...
            zeros(size(rawExpertRisk));
    else
        normalizedExpertRisk = ...
            (rawExpertRisk - 1 / K) ...
            / (1 - 1 / K);
    end

end
