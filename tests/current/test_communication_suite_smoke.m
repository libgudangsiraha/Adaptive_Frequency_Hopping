clear; clc; close all;
setup_paths();
clear functions;
rehash;
setup_paths();

run('tests/current/test_bc_dual_channel_exact.m');
run('tests/current/test_reward_alignment_v2.m');
run('tests/current/test_hybrid_expert_bank_v2.m');
run('tests/current/test_checkpoint_resume_v2.m');

outputs = run_pact_afh_communication_module("C2", "smoke");
assert(istable(outputs.C2.table));
assert(all(isfinite(outputs.C2.table.Reward)));
assert(all(isfinite(outputs.C2.table.GoodputMbps)));
assert(all(outputs.C2.table.Reward >= 0 & outputs.C2.table.Reward <= 1));

disp("PACT-AFH communication v2 smoke test passed.");
