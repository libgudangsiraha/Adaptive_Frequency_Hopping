clear; clc; close all;

setup_paths();

suite = get_final_c1_c4_config("smoke");
assert(suite.beta == 16);
assert(suite.nu == 0);

tableC1 = build_final_c1_table("smoke");
assert(istable(tableC1));
assert(height(tableC1) >= 10);

safe = run_dynamic_safe_projection_scan("smoke");
assert(istable(safe.tableS1));

c2 = run_final_c2("smoke");
c3 = run_final_c3("smoke");
c4 = run_final_c4("smoke");

assert(istable(c2.tableC2));
assert(istable(c3.tableC3));
assert(istable(c4.tableC4));

assert(any(c2.tableC2.Learner == "D-PACT-Safe95"));
assert(any(c3.tableC3.Learner == "D-PACT-Safe95"));
assert(all(isfinite(c4.tableC4.MasterLocalMass)));

disp("Complete C1-C4 rebuild smoke test passed.");
