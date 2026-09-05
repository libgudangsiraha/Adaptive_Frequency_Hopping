clear; clc;
setup_paths();

cfg = get_base_config();
cfg.K = 2;
cfg.reward_mode = "outage_capped";
cfg.sinr_outage_threshold_dB = 3;

h = [1; 1];
occ = [0; 0];
noise = [0.05; 0.05];
jammed = [1; 0];

outcomes = compute_all_arm_outcomes(h, occ, noise, jammed, cfg);

assert(outcomes.packetSuccess(1) == 0);
assert(outcomes.reward(1) == 0);
assert(outcomes.goodputMbps(1) == 0);
assert(outcomes.packetSuccess(2) == 1);
assert(outcomes.reward(2) > 0);
assert(outcomes.goodputMbps(2) > 0);

cfg.reward_mode = "fixed_packet";
outcomesFixed = compute_all_arm_outcomes( ...
    h, occ, noise, jammed, cfg);
assert(outcomesFixed.reward(1) == 0);
assert(outcomesFixed.reward(2) == 1);

disp("PACT-AFH v2 reward-alignment test passed.");
