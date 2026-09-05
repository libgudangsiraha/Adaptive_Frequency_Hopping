clear; clc; close all;

setup_paths();

run('tests/current/test_kl_hit_risk_projection_exact.m');

outputs = run_dynamic_safe_projection_scan("smoke");

assert(istable(outputs.tableS1));
assert(istable(outputs.tableS2));
assert(istable(outputs.tableS3));
assert(istable(outputs.tableS4));

assert(all(isfinite(outputs.tableS1.GoodputMbps)));
assert(all(isfinite(outputs.tableS1.EmpiricalJamHit)));
assert(all(outputs.tableS1.MaxBudgetViolation < 1e-7));

disp("D-PACT-Safe projection smoke test passed.");
