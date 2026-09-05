# Method

## D-PACT-AFH

D-PACT-AFH is a risk-aware adaptive frequency-hopping framework built around
two online base learners:

1. **LC-Tsallis-INF-Online**, a linear contextual learner;
2. **Partitioned Local-Linear**, a local contextual learner that can represent
   regime-dependent sign changes and piecewise behavior.

At each round the base policies are combined by a Tsallis-FTRL master. The
communication channel is learned from bandit feedback, while the current
prediction-risk signal is available as a full-information side channel.

The final implementation contains three paper-facing operating modes:

- **D-PACT-Base** — dynamic model selection without prediction-risk control;
- **D-PACT-Hit** — adds prediction-aware risk to the master/exploration logic;
- **D-PACT-Safe95** — adds a KL projection onto a calibrated hit-risk budget.

The safe projection solves the minimum-KL change from the unconstrained policy
subject to a current-round expected hit-risk constraint.

## Implementation map

```text
config/          frozen experiment configurations
env/             communication environment and reward model
adversaries/     random, sweep, contextual, and adaptive attack models
learners/        D-PACT, LC, local-linear, EXP3/EXP4-related learner logic
experts/         policy/expert construction
policies/        exploration and Tsallis-FTRL policy utilities
core/            per-seed execution, aggregation, resume/checkpoint logic
metrics/         communication and risk metrics
diagnostics/     model-mismatch / expressivity diagnostics
experiments/     final C1--C6 communication experiments
plots/           paper plotting routines
tables/          CSV/LaTeX table builders
```

## Final communication suite

The frozen v3.8 paper suite contains:

- **C1** system parameters;
- **C2** running performance and endpoint tradeoff;
- **C3** cross-attacker robustness;
- **C4** mechanism/model ablation;
- **C4b** model-selection effects;
- **C5** environment-regime robustness;
- **C6** channel/horizon/runtime scaling;
- **S1/S2** calibrated safe frontier / safe operating points.

The final C1--C4 configuration uses a frozen D-PACT operating point and common
seed lists across compared learners. See `config/get_final_c1_c4_config.m`.
