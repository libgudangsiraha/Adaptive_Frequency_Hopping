# D-PACT-Safe v3.3

This patch adds a KL risk-projection layer without changing the frozen
D-PACT dynamic backbone or calibrated hit-risk master.

\[
\min_{\pi\in\Delta_K}
D_{\mathrm{KL}}(\pi\|\bar\pi)
\quad
\text{s.t.}
\quad
\pi^\top h_t\le\tau.
\]

## Run

```matlab
clear functions
rehash
setup_paths
run('tests/current/test_dynamic_safe_projection_smoke.m')
```

Then:

```matlab
safe = run_dynamic_safe_projection_scan("quick");
safe = run_dynamic_safe_projection_scan("full");
```

- `D-PACT-Hit`: high-throughput unconstrained point.
- `D-PACT-Safe-balanced`: balanced constrained point.
- `D-PACT-Safe-low_risk`: lowest-risk point retaining at least 95% of
  unconstrained D-PACT-Hit goodput.
