%REPRODUCE_PAPER Rebuild the final D-PACT-AFH communication-paper bundle.
clear functions
rehash
setup_paths

tic
final = run_complete_communication_rebuild("full"); %#ok<NASGU>
elapsedHours = toc / 3600;
fprintf("Full paper rebuild completed in %.3f hours.\n", elapsedHours);
