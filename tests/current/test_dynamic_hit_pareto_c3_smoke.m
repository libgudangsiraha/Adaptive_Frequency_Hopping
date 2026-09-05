clear; clc; close all;

setup_paths();

pareto = run_dynamic_hit_pareto_scan("smoke");

assert(istable(pareto.tableP1));
assert(istable(pareto.tableP2));
assert(height(pareto.tableP2) == 3);
assert(all(isfinite(pareto.tableP1.GoodputMbps)));
assert(all(isfinite(pareto.tableP1.EmpiricalJamHit)));

c3 = run_dynamic_hit_c3("smoke", "balanced");

assert(istable(c3.tableC3));
assert(istable(c3.tableEffects));
assert(all(isfinite(c3.tableC3.GoodputMbps)));
assert(all(isfinite(c3.tableC3.EmpiricalJamHit)));

disp("Dynamic hit-risk Pareto and C3 smoke test passed.");
