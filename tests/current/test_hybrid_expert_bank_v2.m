clear; clc;
setup_paths();

cfg = get_base_config();
cfg.K = 6;
cfg.pact_expert_bank_mode = "hybrid";
expertCfg = get_pact_expert_config(cfg);
bank = build_pact_experts(expertCfg);

X = zeros(cfg.contextDim, cfg.K);
X(1, :) = 1;
X(2, :) = linspace(0, 1, cfg.K);
X(3, :) = linspace(1, 0, cfg.K);
X(4, :) = [1, 1, 0, 1, 0, 1];

advice = evaluate_pact_experts(X, bank);

assert(size(advice, 1) == cfg.K);
assert(size(advice, 2) == bank.numExperts);
assert(any(bank.familyIndex == 1));
assert(any(bank.familyIndex == 2));
assert(all(abs(sum(advice, 1) - 1) < 1e-10));
assert(all(advice(:) >= 0));

disp("PACT-AFH v2 hybrid expert-bank test passed.");
