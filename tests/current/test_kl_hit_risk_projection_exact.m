clear; clc;

setup_paths();

p0 = [0.55; 0.25; 0.15; 0.05];
h = [0.40; 0.20; 0.10; 0.05];

[p, info] = project_policy_kl_hit_risk( ...
    p0, h, 0.15, 1e-12, 100);

assert(abs(sum(p) - 1) < 1e-12);
assert(all(p >= 0));
assert(p' * h <= 0.15 + 1e-9);
assert(info.active);
assert(info.feasible);
assert(info.klDivergence >= 0);

[pInactive, inactiveInfo] = ...
    project_policy_kl_hit_risk( ...
        p0, h, 0.50, 1e-12, 100);

assert(norm(pInactive - p0 / sum(p0), Inf) < 1e-12);
assert(~inactiveInfo.active);

uniformRisk = ones(4, 1) / 4;
[pUniform, uniformInfo] = ...
    project_policy_kl_hit_risk( ...
        p0, uniformRisk, 0.30, 1e-12, 100);

assert(norm(pUniform - p0 / sum(p0), Inf) < 1e-12);
assert(~uniformInfo.active);

disp("Exact KL hit-risk projection test passed.");
