clear; clc; close all;

setup_paths();

outputs = run_pact_model_diagnostics("smoke");

assert(istable(outputs.tableD1));
assert(istable(outputs.tableD2));
assert(istable(outputs.tableD3));
assert(istable(outputs.tableD4));

assert(all(isfinite(outputs.tableD1.OracleCapture)));
assert(all(isfinite(outputs.tableD2.FixedOracleCapture)));
assert(all(isfinite(outputs.tableD3.GoodputMbps)));
assert(all(isfinite(outputs.tableD4.FixedOracleCapture)));

assert(isfile(outputs.reportPath));

disp("PACT-AFH model diagnostic smoke test passed.");
