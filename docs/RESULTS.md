# Paper-Facing Results

The repository includes only lightweight final paper artifacts.

```text
results/paper_complete/full/
├── COMPLETE_PAPER_MANIFEST.md
├── figures/
└── tables/
```

The included figures cover final running performance, endpoint tradeoffs,
cross-attacker robustness, ablation/model-selection behavior, regime
robustness, scaling, and the Safe risk--goodput frontier.

Raw simulation matrices, resumable checkpoints, and intermediate development
outputs are intentionally excluded because the original project contains
multiple gigabytes of MATLAB artifacts. They can be regenerated using
`run_complete_communication_rebuild("full")`.

No archived prototype result is used as a substitute for the final v3.8
communication suite.
