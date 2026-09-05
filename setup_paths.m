function projectRoot = setup_paths()
%SETUP_PATHS Add only active PACT-AFH v2 folders to the MATLAB path.
%
% Archived scripts/tests are intentionally excluded to prevent stale local
% functions from shadowing the active implementation.

    projectRoot = fileparts(mfilename("fullpath"));

    activeFolders = [
        "config"
        "env"
        "adversaries"
        "learners"
        "experts"
        "core"
        "metrics"
        "plots"
        "policies"
        "tables"
        "diagnostics"
        fullfile("tests", "current")
        fullfile("experiments", "communication")
    ];

    for index = 1:numel(activeFolders)
        folderPath = fullfile(projectRoot, activeFolders(index));
        if isfolder(folderPath)
            addpath(folderPath);
        end
    end

end
