# v3.8 complete C1-C6 rebuild

The old C1-C4 result folders are not required. Their final experiments
are regenerated from the retained source code.

Do not use the legacy:

```matlab
run_pact_afh_communication_module("C2", ...)
run_pact_afh_communication_module("C4", ...)
```

for the final paper. Those runners belong to the earlier `bc_*`
prototype. v3.8 supplies final D-PACT runners.

## First: smoke test

```matlab
clear functions
rehash
setup_paths

run('tests/current/test_complete_rebuild_smoke.m')
```

## Then: complete full rebuild

```matlab
clear functions
rehash
setup_paths

tic
final = run_complete_communication_rebuild("full");
fullHours = toc / 3600
```

The runner:

1. generates C1;
2. reruns the Safe frontier when absent;
3. reruns final C2, C3, and C4 when absent;
4. reuses completed model-probe and C5 results;
5. reruns C6 only when absent;
6. resumes every completed seed;
7. creates one complete paper folder.

## Final folder

```text
results/paper_complete/full/
├─ COMPLETE_PAPER_MANIFEST.md
├─ raw/COMPLETE_PAPER_RESULTS.mat
├─ tables/
│  ├─ Table_C1_system_parameters.csv
│  ├─ Table_C2_main_performance.csv
│  ├─ Table_C3_cross_attacker.csv
│  ├─ Table_C4_ablation.csv
│  ├─ Table_C4b_model_selection_effects.csv
│  ├─ Table_C5_regime_robustness.csv
│  ├─ Table_C6_scaling.csv
│  ├─ Table_S1_safe_frontier.csv
│  └─ Table_S2_safe_points.csv
└─ figures/
   ├─ Figure_C2_running_performance.png/.pdf
   ├─ Figure_C2_endpoint_tradeoff.png/.pdf
   ├─ Figure_C3_cross_attacker_heatmaps.png/.pdf
   ├─ Figure_C3_cross_attacker_tradeoff.png/.pdf
   ├─ Figure_C4_mechanism_ablation.png/.pdf
   ├─ Figure_C4b_model_selection.png
   ├─ Figure_C5_regime_summary.png
   ├─ Figure_C6_scaling.png
   └─ Figure_S1_safe_frontier.png
```

The full C2-C4 experiments use the frozen final operating point:

```text
beta = 16
nu   = 0
M     = 1
Safe = safe95
```
