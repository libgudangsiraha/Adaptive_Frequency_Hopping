clear; clc; close all;

setup_paths();

run('tests/current/test_attack_inclusion_probability_exact.m');
run('tests/current/test_fixed_size_attack_sampler.m');

outputs = run_hit_risk_alignment_rerun("smoke");

assert(istable(outputs.tableH1));
assert(istable(outputs.tableH2));
assert(height(outputs.tableH1) == 4);
assert(all(isfinite(outputs.tableH1.GoodputMbps)));
assert(all(isfinite(outputs.tableH1.ExpectedJamHit)));
assert(all(isfinite(outputs.tableH1.EmpiricalJamHit)));
assert(isfile(outputs.reportPath));

% Smoke mode is too small for a performance claim, but the model-based
% expectation and empirical hit rate must at least be numerically coherent.
assert(all(abs(outputs.tableH1.CalibrationGap) < 0.20));

disp("Hit-risk alignment smoke test passed.");
