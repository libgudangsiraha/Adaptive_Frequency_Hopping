clear; clc; close all;

setup_paths();

cfg = get_base_config();
cfg.K = 8;
cfg.T = 200;
cfg.occ_prob = 0.10;

for regime = [ ...
        "nonlinear_interaction", ...
        "observable_switching"]

    cfg.environment_regime = regime;
    rng(99601, "twister");

    env = generate_environment(cfg);

    assert(all(size(env.context) == ...
        [cfg.contextDim, cfg.K, cfg.T]));

    assert(any( ...
        env.nonlinearOutcomeInterference(:) > 0));

    assert(all(isfinite(env.noisePower), "all"));

    diagnostic = evaluate_model_mismatch_oracle(cfg);

    assert(isfinite(diagnostic.globalCapture));
    assert(isfinite(diagnostic.localCapture));
    assert(isfinite(diagnostic.captureGain));
end

preflight = run_model_mismatch_preflight("smoke");

assert(istable(preflight.tableP));
assert(height(preflight.tableP) == 2);
assert(all(isfinite( ...
    preflight.tableP.LocalMinusGlobalCapture)));

disp("Model-mismatch preflight smoke test passed.");
