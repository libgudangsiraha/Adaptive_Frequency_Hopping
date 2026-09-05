# D-PACT-AFH: Dynamic-Base Prototype

This branch replaces the static expert backbone with a dynamic master over:

1. **LC-Tsallis-INF-Online**, preserving the strong linear contextual model;
2. **Partitioned Local-Linear**, which maintains separate online ridge models
   in joint context cells and can learn different coefficient signs locally.

The public prediction distribution remains integrated through:

- the dual-channel current-round prediction-risk loss;
- prediction-aware exploration tilt.

## Internal learner types

```text
dpact_nodetect       D-PACT-AFH-Base
dpact_loss_only      D-PACT-AFH-L
dpact_explore_only   D-PACT-AFH-T
dpact_detect         D-PACT-AFH
```

The name **D-PACT-AFH** is provisional until validation is complete.

## First run

```matlab
clear functions
rehash
setup_paths

run('tests/current/test_dynamic_pact_exact.m')
run('tests/current/test_dynamic_pact_smoke.m')
```

Then run the targeted validation:

```matlab
tic
outputs = run_dynamic_pact_validation("quick");
elapsedMinutes = toc / 60
```

Read first:

```text
results/dynamic_pact_validation/quick/VALIDATION_VERDICT.md
```

## Frozen validation requirements

1. `D-PACT LC-only` reproduces native LC within 1%.
2. `D-PACT-AFH-Base` retains at least 98% of LC goodput in the current
   linear-friendly no-jammer environment.
3. The dynamic local learner or master improves LC on XOR, band-pass, or
   weight-flip contextual tasks.
4. Full D-PACT materially lowers prediction overlap under the contextual
   predictor. A later strength sweep determines goodput crossover.

## Architecture

At round t, the two adaptive base learners publish policies

\[
\rho_{t,1}=\pi_t^{\mathrm{LC}},\qquad
\rho_{t,2}=\pi_t^{\mathrm{local}}.
\]

The master estimates each base policy's communication loss by

\[
\widehat \ell_{t,m}
=
\rho_{t,m}(A_t)\frac{1-r_t(A_t)}{\pi_t(A_t)}.
\]

The full-information risk signal is

\[
g_{t,m}
=
\frac{\langle \rho_{t,m},q_t\rangle-1/K}{1-1/K}.
\]

The master applies Tsallis-FTRL to

\[
L^{\rm comm}_{t-1}
+\beta\left(Q^{\rm pred}_{t-1}+g_t\right).
\]

The base mixture is followed by the existing q-aware exploration tilt.

## Local nonlinear learner

The local learner partitions the three current communication features into
joint cells. Each cell has an independently learned affine loss model:

\[
\widehat \ell(x)=\theta_c^\top[1;x],\qquad c=\operatorname{cell}(x).
\]

Because each cell has independent coefficients, the model can learn local
sign changes and piecewise behavior that the old globally monotone static
experts could not represent.

## Important theoretical status

This is an **engineering and experimental prototype**, not yet a completed
CORRAL theorem. The master uses dynamic policies and capped off-policy base
updates. The prediction-aware mechanism is inherited from the validated
static version, but the complete regret proof for adaptive base learners
must be developed separately before the mathematical paper freezes.

Do not replace the existing paper-scale communication results until the
quick validation passes the frozen criteria.
