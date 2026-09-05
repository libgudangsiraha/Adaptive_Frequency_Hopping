clear; clc; close all;

setup_paths();

cfg = get_base_config();
cfg.K = 8;
cfg.T = 40;

for regime = ["nonlinear_interaction", "observable_switching"]

    cfg.environment_regime = regime;
    env = generate_environment(cfg);

    assert(all(size(env.context) == [cfg.contextDim, cfg.K, cfg.T]));
    assert(all(size(env.noisePower) == [cfg.K, cfg.T]));
    assert(any(env.nonlinearOutcomeInterference(:) > 0));
    assert(all(isfinite(env.noisePower), "all"));
end

probe = run_dynamic_model_class_probe("smoke");

assert(istable(probe.tableM));
assert(height(probe.tableM) == 8);
assert(all(isfinite(probe.tableM.GoodputMbps)));

c5 = run_dynamic_safe_c5("smoke");

assert(any(c5.tableC5.Regime == "Nonlinear interaction"));
assert(any(c5.tableC5.Regime == "Observable switching"));
assert(ismember("MasterLocalMass", ...
    string(c5.tableC5.Properties.VariableNames)));

disp("Nonlinear C5 extension smoke test passed.");
