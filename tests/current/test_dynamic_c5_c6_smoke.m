clear; clc; close all;

setup_paths();

c5 = run_dynamic_safe_c5("smoke");

assert(istable(c5.tableC5));
assert(istable(c5.tableEffects));
assert(all(isfinite(c5.tableC5.GoodputMbps)));
assert(all(isfinite(c5.tableC5.EmpiricalJamHit)));

hiddenRows = c5.tableC5.Regime == "Hidden Markov";
assert(any(hiddenRows));
assert(all(isfinite(c5.tableC5.GoodputMbps(hiddenRows))));

c6 = run_dynamic_safe_c6("smoke");

assert(istable(c6.tableC6));
assert(all(isfinite(c6.tableC6.GoodputMbps)));
assert(all(isfinite(c6.tableC6.RuntimeSeconds)));

safeRows = c6.tableC6.Learner == "D-PACT-Safe95";
assert(all(isfinite(c6.tableC6.Tau(safeRows))));

disp("Dynamic C5/C6 smoke test passed.");
