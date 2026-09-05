clear; clc;

setup_paths();

%% M = 1 must reduce exactly to q.
q = [0.30; 0.20; 0.15; 0.12; 0.08; 0.06; 0.04; 0.03; 0.015; 0.005];
q = q / sum(q);

h1 = attack_inclusion_probability(q, 1);
assert(max(abs(h1 - q)) < 1e-10);
assert(abs(sum(h1) - 1) < 1e-10);

%% Uniform q must produce uniform M/K marginals.
K = 12;
M = 3;
hUniform = attack_inclusion_probability(ones(K, 1) / K, M);
assert(max(abs(hUniform - M / K)) < 1e-10);
assert(abs(sum(hUniform) - M) < 1e-10);

%% Concentrated q must remain capped and preserve the budget.
qConcentrated = [0.80; 0.10; 0.04; 0.03; 0.02; 0.01];
hConcentrated = attack_inclusion_probability(qConcentrated, 2);
assert(all(hConcentrated >= 0));
assert(all(hConcentrated <= 1));
assert(abs(sum(hConcentrated) - 2) < 1e-9);
assert(hConcentrated(1) == 1);

%% Boundary budgets.
assert(all(attack_inclusion_probability(q, 0) == 0));
assert(all(attack_inclusion_probability(q, numel(q)) == 1));

disp("Attack inclusion-probability exact test passed.");
