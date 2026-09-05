function outputs = run_pact_afh_communication_suite(mode)
%RUN_PACT_AFH_COMMUNICATION_SUITE Backward-compatible v2 full entry point.

    if nargin < 1, mode = "smoke"; end
    outputs = run_pact_afh_communication_module("ALL", mode);

end
