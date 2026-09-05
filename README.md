# Adaptive Frequency Hopping

**Risk-aware adaptive frequency hopping with multi-armed bandits and online learning.**

This repository contains the paper-companion MATLAB implementation of
**D-PACT-AFH**, an adaptive frequency-hopping framework for communication under
uncertain and potentially predictive interference.

The project studies sequential channel selection under two coupled objectives:
high communication utility and controlled exposure to an adversary that can
exploit predictable hopping behavior.

## Highlights

- online channel selection under bandit feedback;
- dynamic selection between linear-contextual and local-contextual models;
- Tsallis-FTRL master over adaptive base learners;
- prediction-risk-aware exploration;
- fixed-budget attack-set inclusion risk;
- KL-constrained risk projection for **D-PACT-Safe95**;
- resumable per-seed experiments;
- common-seed comparisons against classical and modern bandit baselines;
- paper-scale robustness, ablation, and scaling experiments.

## D-PACT Variants

- **D-PACT-Base** — adaptive model selection without prediction-risk control.
- **D-PACT-Hit** — risk-aware high-throughput operating point.
- **D-PACT-Safe95** — constrained point selected to retain at least 95% of the
  unconstrained D-PACT-Hit goodput while reducing expected hit exposure.

## Baselines

The final paper suite includes representative baselines such as:

- UCB
- Thompson Sampling
- EXP3
- LC-Tsallis-INF-Online
- risk-aware EXP4
- AUFH-EXP3++

## Quick Start

Open MATLAB in the repository root:

```matlab
clear functions
rehash
setup_paths
```

Run the fast release checks:

```matlab
run('scripts/verify_release.m')
```

Run the complete final communication-paper suite:

```matlab
final = run_complete_communication_rebuild("full");
```

The full experiment is resumable: completed per-seed checkpoints are reused.

## Repository Structure

```text
adversaries/                  attack models
config/                       frozen experiment configurations
core/                         execution, aggregation, checkpoint/resume
diagnostics/                  model diagnostics
env/                          communication environment and reward
experts/                      policy/expert construction
learners/                     online learners and D-PACT
metrics/                      evaluation metrics
plots/                        publication plots
policies/                     policy utilities
tables/                       table generation
experiments/communication/    final experiment runners
tests/current/                active tests
results/paper_complete/full/  paper-facing figures and tables
docs/                         method and reproducibility documentation
```

## Final Experiment Bundle

The frozen v3.8 paper suite includes C1--C6 plus the Safe frontier:

- C1 — system parameters
- C2 — running performance / endpoint tradeoff
- C3 — cross-attacker robustness
- C4 — mechanism ablation
- C4b — model-selection behavior
- C5 — environment-regime robustness
- C6 — channel/horizon/runtime scaling
- S1/S2 — risk--goodput frontier and calibrated safe operating points

See [`docs/RESULTS.md`](docs/RESULTS.md).

## Reproducibility

Detailed instructions are in
[`docs/REPRODUCIBILITY.md`](docs/REPRODUCIBILITY.md).

The public repository includes the final lightweight figures and tables, but
not the original multi-gigabyte raw MATLAB result/checkpoint tree. Those
artifacts are reproducible from the retained v3.8 source.

## Paper

Paper/preprint URL: **to be added when public**.

## Citation

The final BibTeX entry will be added when the corresponding manuscript or
preprint is public.

## Author

**Chen Yanbo**

Research interests: signal processing, wireless communications, machine
learning, online learning, optimization, and intelligent systems.
