# Reproducibility

## Requirements

- MATLAB
- Parallel Computing Toolbox is optional. If available, independent seeds can
  run in parallel; otherwise the same experiment code runs serially.

No Python environment is required for the communication experiments.

## Setup

Open MATLAB in the repository root:

```matlab
clear functions
rehash
setup_paths
```

## Fast unit verification

```matlab
run('tests/current/test_attack_inclusion_probability_exact.m')
run('tests/current/test_dynamic_pact_exact.m')
run('tests/current/test_kl_hit_risk_projection_exact.m')
run('tests/current/test_reward_alignment_v2.m')
run('tests/current/test_fixed_size_attack_sampler.m')
run('tests/current/test_hybrid_expert_bank_v2.m')
```

Or run:

```matlab
run('scripts/verify_release.m')
```

## Smoke rebuild

The final communication-suite smoke test is:

```matlab
run('tests/current/test_complete_rebuild_smoke.m')
```

It runs small C1--C4 experiments and therefore writes temporary result
artifacts under `results/`.

## Full paper rebuild

```matlab
tic
final = run_complete_communication_rebuild("full");
elapsedHours = toc / 3600
```

The full runner:

1. creates C1;
2. calibrates/reuses the Safe frontier;
3. runs/reuses C2, C3, and C4;
4. reuses or regenerates the model-class probe and C5;
5. runs C6 when missing;
6. resumes completed per-seed work;
7. assembles `results/paper_complete/full/`.

The repository intentionally does not ship multi-gigabyte `*.mat` raw results.
The checked-in paper-facing figures/tables are under
`results/paper_complete/full/`.
