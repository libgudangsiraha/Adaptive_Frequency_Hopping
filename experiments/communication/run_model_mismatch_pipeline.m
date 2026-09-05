function outputs = run_model_mismatch_pipeline(mode)
%RUN_MODEL_MISMATCH_PIPELINE Fast and stable development workflow.
%
% 1. Run the cheap offline model-class preflight.
% 2. Launch the online bandit probe only when both regimes pass.

    if nargin < 1
        mode = "quick";
    end

    preflight = run_model_mismatch_preflight(mode);

    outputs.preflight = preflight;
    outputs.probe = [];

    if ~preflight.allPass
        warning([ ...
            "Online probe skipped because the model-mismatch " ...
            "preflight did not pass."]);
        return;
    end

    outputs.probe = run_dynamic_model_class_probe(mode);

end
