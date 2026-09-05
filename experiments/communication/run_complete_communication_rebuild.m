function outputs = run_complete_communication_rebuild(mode)
%RUN_COMPLETE_COMMUNICATION_REBUILD Rebuild all final paper modules.
%
% This entry point is designed for the case where old intermediate
% result folders were deleted. It regenerates missing results from the
% retained source code and resumes every completed seed.
%
% Order:
%   C1 parameter table;
%   Safe frontier (required to resolve Safe95);
%   C2 main running performance;
%   C3 cross-attacker robustness;
%   C4 mechanism/model ablation;
%   model-class probe;
%   C5 regime robustness;
%   C6 scaling;
%   complete paper bundle.

    if nargin < 1
        mode = "full";
    end

    projectRoot = setup_paths();
    mode = lower(string(mode));

    outputs = struct();

    %% C1
    tableC1 = build_final_c1_table(mode);
    c1Folder = fullfile( ...
        projectRoot, "results", ...
        "paper_complete", char(mode), "tables");

    ensure_folder(c1Folder);

    write_table_bundle(tableC1, fullfile( ...
        c1Folder, "Table_C1_system_parameters"));

    outputs.C1 = tableC1;

    %% Safe frontier and Safe95 calibration
    safePath = fullfile( ...
        projectRoot, "results", ...
        "dynamic_safe_projection", char(mode), ...
        "raw", "S1_dynamic_safe_projection.mat");

    if ~isfile(safePath)
        fprintf("\n[REBUILD] Safe projection scan is missing.\n");
        outputs.Safe = ...
            run_dynamic_safe_projection_scan(mode);
    else
        fprintf("\n[FOUND] Safe projection scan.\n");
    end

    %% C2
    c2Path = fullfile( ...
        projectRoot, "results", ...
        "final_c2", char(mode), ...
        "raw", "C2_final.mat");

    if ~isfile(c2Path)
        outputs.C2 = run_final_c2(mode);
    else
        fprintf("\n[FOUND] Final C2.\n");
    end

    %% C3
    c3Path = fullfile( ...
        projectRoot, "results", ...
        "final_c3", char(mode), ...
        "raw", "C3_final.mat");

    if ~isfile(c3Path)
        outputs.C3 = run_final_c3(mode);
    else
        fprintf("\n[FOUND] Final C3.\n");
    end

    %% C4
    c4Path = fullfile( ...
        projectRoot, "results", ...
        "final_c4", char(mode), ...
        "raw", "C4_final.mat");

    if ~isfile(c4Path)
        outputs.C4 = run_final_c4(mode);
    else
        fprintf("\n[FOUND] Final C4.\n");
    end

    %% Model-class probe
    probePath = fullfile( ...
        projectRoot, "results", ...
        "dynamic_model_class_probe", char(mode), ...
        "raw", "C5M_model_class_probe.mat");

    if ~isfile(probePath)
        outputs.ModelProbe = ...
            run_dynamic_model_class_probe(mode);
    else
        fprintf("\n[FOUND] Model-class probe.\n");
    end

    %% C5
    c5Path = fullfile( ...
        projectRoot, "results", ...
        "dynamic_c5", char(mode), ...
        "raw", "C5_dynamic_safe.mat");

    if ~isfile(c5Path)
        outputs.C5 = run_dynamic_safe_c5(mode);
    else
        fprintf("\n[FOUND] Final C5.\n");
    end

    %% C6
    c6Path = fullfile( ...
        projectRoot, "results", ...
        "dynamic_c6", char(mode), ...
        "raw", "C6_dynamic_safe.mat");

    if ~isfile(c6Path)
        outputs.C6 = run_dynamic_safe_c6(mode);
    else
        fprintf("\n[FOUND] Final C6.\n");
    end

    %% Complete assembly
    outputs.Final = ...
        finalize_complete_communication_paper(mode);

end


function ensure_folder(pathValue)

    if ~isfolder(pathValue)
        mkdir(pathValue);
    end

end
