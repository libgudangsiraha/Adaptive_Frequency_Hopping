function outputs = run_final_communication_stage(runMissingC5)
%RUN_FINAL_COMMUNICATION_STAGE Complete and package final paper results.
%
% outputs = run_final_communication_stage(true)
%   Runs C5 full only when its final MAT file is missing, then builds the
%   paper-ready result bundle.
%
% outputs = run_final_communication_stage(false)
%   Never launches experiments; only assembles existing full results.

    if nargin < 1
        runMissingC5 = true;
    end

    projectRoot = setup_paths();

    c5Path = fullfile( ...
        projectRoot, ...
        "results", ...
        "dynamic_c5", ...
        "full", ...
        "raw", ...
        "C5_dynamic_safe.mat");

    if ~isfile(c5Path)

        if ~runMissingC5
            error("C5 full result is missing: %s", c5Path);
        end

        fprintf("\nC5 full result is missing. Running C5 full now.\n");
        run_dynamic_safe_c5("full");
    else
        fprintf("\nC5 full result found. No C5 recomputation needed.\n");
    end

    outputs = finalize_communication_results("full");

end
