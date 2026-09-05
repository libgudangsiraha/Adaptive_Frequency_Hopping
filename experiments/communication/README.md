# Communication v2 modules

Run from the project root:

```matlab
setup_paths
run_pact_afh_communication_module("C2", "quick")
run_pact_afh_communication_module("ROBUSTNESS", "quick")
run_pact_afh_communication_module("C6", "full")
```

Available modules:

- `C2`
- `C3`
- `C4`
- `C5`
- `PARETO`
- `ROBUSTNESS`
- `C6`
- `ALL`

Every completed seed is stored under the mode-specific `checkpoints/`
folder and is reused automatically after restart.
