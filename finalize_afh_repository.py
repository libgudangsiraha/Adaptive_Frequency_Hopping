#!/usr/bin/env python
r"""
One-shot public-repository finalizer for the D-PACT-AFH / Adaptive Frequency
Hopping communication project.

Default source:
    D:\实验\跳频改\pact_comm_project_v3_8

Default destination:
    D:\Github\Adaptive_Frequency_Hopping

The source project is READ ONLY. The script copies the active MATLAB
implementation, current tests, and paper-facing figures/tables into the Git
repository, writes publication-oriented documentation, and performs static
release checks.

It intentionally does NOT copy:
- results/raw MAT files (~GB scale)
- checkpoints / caches / tmp
- archived/development experiments and tests
- the separate application-mathematics manuscript under paper_pact_math
- handoff prompts / internal work logs
"""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import textwrap
from typing import Iterable


PROJECT_DEFAULT = r"D:\实验\跳频改\pact_comm_project_v3_8"
REPO_DEFAULT = r"D:\Github\Adaptive_Frequency_Hopping"

ACTIVE_DIRS = (
    "adversaries",
    "config",
    "core",
    "diagnostics",
    "env",
    "experts",
    "learners",
    "metrics",
    "plots",
    "policies",
    "tables",
)

ACTIVE_EXPERIMENT_DIR = Path("experiments") / "communication"
ACTIVE_TEST_DIR = Path("tests") / "current"

PAPER_RESULT_ROOT = Path("results") / "paper_complete" / "full"
PAPER_RESULT_ITEMS = (
    Path("COMPLETE_PAPER_MANIFEST.md"),
    Path("figures"),
    Path("tables"),
)

EXPECTED_PAPER_FIGURES = {
    "Figure_C2_endpoint_tradeoff.pdf",
    "Figure_C2_endpoint_tradeoff.png",
    "Figure_C2_running_performance.pdf",
    "Figure_C2_running_performance.png",
    "Figure_C3_cross_attacker_heatmaps.pdf",
    "Figure_C3_cross_attacker_heatmaps.png",
    "Figure_C3_cross_attacker_tradeoff.pdf",
    "Figure_C3_cross_attacker_tradeoff.png",
    "Figure_C4b_model_selection.png",
    "Figure_C4_mechanism_ablation.pdf",
    "Figure_C4_mechanism_ablation.png",
    "Figure_C5_regime_summary.png",
    "Figure_C6_scaling.png",
    "Figure_S1_safe_frontier.png",
}

EXPECTED_PAPER_TABLES = {
    "Table_C1_system_parameters.csv",
    "Table_C1_system_parameters.tex",
    "Table_C2_main_performance.csv",
    "Table_C2_main_performance.tex",
    "Table_C3_cross_attacker.csv",
    "Table_C3_cross_attacker.tex",
    "Table_C4b_model_selection_effects.csv",
    "Table_C4b_model_selection_effects.tex",
    "Table_C4_ablation.csv",
    "Table_C4_ablation.tex",
    "Table_C5_regime_robustness.csv",
    "Table_C5_regime_robustness.tex",
    "Table_C6_scaling.csv",
    "Table_C6_scaling.tex",
    "Table_S1_safe_frontier.csv",
    "Table_S1_safe_frontier.tex",
    "Table_S2_safe_points.csv",
    "Table_S2_safe_points.tex",
}

ROOT_SOURCE_FILES = ("setup_paths.m",)

DOC_SOURCE_FILES = (
    "COMPLETE_REBUILD_CHANGELOG_V3_8.md",
    "RUN_COMPLETE_REBUILD_V3_8.md",
    "README_DYNAMIC_PACT.md",
    "README_DYNAMIC_SAFE_PROJECTION.md",
    "FINAL_COMMUNICATION_CHANGELOG_V3_7.md",
    "FILE_MANIFEST_V3_8.md",
)

UNIT_TESTS = (
    "test_attack_inclusion_probability_exact.m",
    "test_dynamic_pact_exact.m",
    "test_kl_hit_risk_projection_exact.m",
    "test_reward_alignment_v2.m",
    "test_fixed_size_attack_sampler.m",
    "test_hybrid_expert_bank_v2.m",
)

TEXT_EXTS = {
    ".m", ".md", ".txt", ".csv", ".tex", ".json",
    ".yaml", ".yml", ".toml", ".py",
}

ABS_PATH_PATTERNS = (
    re.compile(r"\b[A-Za-z]:\\[^\"'\r\n]+"),
    re.compile(r"/home/[^\"'\s]+"),
)

SECRET_PATTERNS = (
    re.compile(r"\bsk-[A-Za-z0-9_-]{16,}"),
    re.compile(r"\bgh[pousr]_[A-Za-z0-9]{20,}"),
    re.compile(
        r"(?i)\b(api[_-]?key|access[_-]?token|password|secret)"
        r"\s*[:=]\s*[\"'][^\"']{6,}[\"']"
    ),
)


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        textwrap.dedent(text).strip() + "\n",
        encoding="utf-8",
        newline="\n",
    )


def copy_file(src: Path, dst: Path) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)


def primary_matlab_function(path: Path) -> str | None:
    """Return first declared MATLAB function name; scripts return None."""
    text = path.read_text(encoding="utf-8-sig", errors="replace")
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("%"):
            continue
        if not line.lower().startswith("function"):
            return None
        after = line[len("function"):].strip()
        if "=" in after:
            after = after.split("=", 1)[1].strip()
        match = re.match(r"([A-Za-z]\w*)\s*(?:\(|$)", after)
        return match.group(1) if match else None
    return None


def run(cmd: list[str], cwd: Path, check: bool = True) -> subprocess.CompletedProcess[str]:
    print("$", " ".join(cmd))
    proc = subprocess.run(
        cmd,
        cwd=str(cwd),
        text=True,
        capture_output=True,
    )
    if proc.stdout:
        print(proc.stdout.rstrip())
    if proc.stderr:
        print(proc.stderr.rstrip())
    if check and proc.returncode != 0:
        raise RuntimeError(
            f"Command failed ({proc.returncode}): {' '.join(cmd)}"
        )
    return proc


class Finalizer:
    def __init__(self, project: Path, repo: Path, run_matlab: bool):
        self.project = project.resolve()
        self.repo = repo.resolve()
        self.run_matlab = run_matlab
        stamp = dt.datetime.now().strftime("%Y%m%d_%H%M%S")
        self.backup = self.repo / "_staging" / f"afh_finalizer_backup_{stamp}"
        self.docs = self.repo / "docs"
        self.prov = self.docs / "provenance"
        self.manifest_rows: list[dict[str, object]] = []
        self.release_checks: dict[str, object] = {}

    def validate(self) -> None:
        print("\n[1/8] Validate source and destination")

        if not self.project.is_dir():
            raise FileNotFoundError(f"Project root not found: {self.project}")
        if not self.repo.is_dir():
            raise FileNotFoundError(f"Repository root not found: {self.repo}")
        if not (self.repo / ".git").is_dir():
            raise RuntimeError(f"Destination is not a Git repository: {self.repo}")

        required = [
            self.project / "setup_paths.m",
            self.project / ACTIVE_EXPERIMENT_DIR / "run_complete_communication_rebuild.m",
            self.project / "config" / "get_final_c1_c4_config.m",
            self.project / "learners" / "dynamic_pact_select.m",
            self.project / "learners" / "dynamic_pact_update.m",
            self.project / PAPER_RESULT_ROOT / "COMPLETE_PAPER_MANIFEST.md",
        ]
        missing = [str(x) for x in required if not x.is_file()]
        if missing:
            raise FileNotFoundError(
                "Authoritative v3.8 files missing:\n"
                + "\n".join(f"  - {x}" for x in missing)
            )

        try:
            remote = run(
                ["git", "remote", "get-url", "origin"],
                self.repo,
            ).stdout.strip()
            if "Adaptive_Frequency_Hopping" not in remote:
                raise RuntimeError(
                    "origin is not Adaptive_Frequency_Hopping:\n"
                    f"  {remote}"
                )
        except FileNotFoundError:
            print("WARN: git executable not found; remote check skipped.")

        print("PASS")

    def backup_path(self, path: Path) -> None:
        if not path.exists():
            return
        rel = path.relative_to(self.repo)
        dst = self.backup / rel
        dst.parent.mkdir(parents=True, exist_ok=True)
        if path.is_dir():
            if dst.exists():
                shutil.rmtree(dst)
            shutil.copytree(path, dst)
        else:
            shutil.copy2(path, dst)

    def record_copy(self, src: Path, dst: Path, kind: str) -> None:
        copy_file(src, dst)
        dst_sha = sha256_file(dst)
        src_sha = sha256_file(src)
        self.manifest_rows.append(
            {
                "path": dst.relative_to(self.repo).as_posix(),
                "kind": kind,
                "sha256": dst_sha,
                "source_sha256": src_sha,
                "exact_copy": dst_sha == src_sha,
                "size_bytes": dst.stat().st_size,
            }
        )

    def copy_active_source(self) -> None:
        print("\n[2/8] Copy active MATLAB implementation")

        for name in ACTIVE_DIRS:
            self.backup_path(self.repo / name)
            if (self.repo / name).exists():
                shutil.rmtree(self.repo / name)

        self.backup_path(self.repo / ACTIVE_EXPERIMENT_DIR)
        if (self.repo / ACTIVE_EXPERIMENT_DIR).exists():
            shutil.rmtree(self.repo / ACTIVE_EXPERIMENT_DIR)

        self.backup_path(self.repo / ACTIVE_TEST_DIR)
        if (self.repo / ACTIVE_TEST_DIR).exists():
            shutil.rmtree(self.repo / ACTIVE_TEST_DIR)

        for name in ACTIVE_DIRS:
            src_root = self.project / name
            dst_root = self.repo / name
            for src in sorted(src_root.rglob("*.m")):
                self.record_copy(
                    src,
                    dst_root / src.relative_to(src_root),
                    "active_matlab_source",
                )

        exp_src = self.project / ACTIVE_EXPERIMENT_DIR
        for src in sorted(exp_src.rglob("*")):
            if src.is_file() and src.suffix.lower() in {".m", ".md"}:
                self.record_copy(
                    src,
                    self.repo / ACTIVE_EXPERIMENT_DIR / src.relative_to(exp_src),
                    "active_experiment_source",
                )

        test_src = self.project / ACTIVE_TEST_DIR
        for src in sorted(test_src.rglob("*.m")):
            self.record_copy(
                src,
                self.repo / ACTIVE_TEST_DIR / src.relative_to(test_src),
                "current_test",
            )

        for name in ROOT_SOURCE_FILES:
            self.backup_path(self.repo / name)
            self.record_copy(
                self.project / name,
                self.repo / name,
                "root_entrypoint",
            )

        print(f"Copied {len(self.manifest_rows)} active files")

    def copy_paper_artifacts(self) -> None:
        print("\n[3/8] Copy paper-facing result artifacts")

        target = self.repo / PAPER_RESULT_ROOT
        self.backup_path(target)
        if target.exists():
            shutil.rmtree(target)

        source_root = self.project / PAPER_RESULT_ROOT

        for item in PAPER_RESULT_ITEMS:
            src = source_root / item
            dst = target / item

            if src.is_file():
                self.record_copy(src, dst, "paper_result_manifest")
                continue

            for file in sorted(src.rglob("*")):
                if not file.is_file():
                    continue
                if file.suffix.lower() not in {".png", ".pdf", ".csv", ".tex", ".md"}:
                    continue
                self.record_copy(
                    file,
                    dst / file.relative_to(src),
                    "paper_facing_artifact",
                )

        mats = list(target.rglob("*.mat"))
        if mats:
            raise RuntimeError(
                "MAT file unexpectedly copied into public release:\n"
                + "\n".join(str(x) for x in mats)
            )

        actual_figures = {p.name for p in (target / "figures").glob("*") if p.is_file()}
        actual_tables = {p.name for p in (target / "tables").glob("*") if p.is_file()}
        missing_figures = sorted(EXPECTED_PAPER_FIGURES - actual_figures)
        missing_tables = sorted(EXPECTED_PAPER_TABLES - actual_tables)
        if missing_figures or missing_tables:
            details = []
            if missing_figures:
                details.append("Missing frozen paper figures: " + ", ".join(missing_figures))
            if missing_tables:
                details.append("Missing frozen paper tables: " + ", ".join(missing_tables))
            raise RuntimeError("\n".join(details))

        print(f"PASS: {len(actual_figures)} paper figure files, {len(actual_tables)} table files")

    def write_docs(self) -> None:
        print("\n[4/8] Write README and public documentation")

        for p in (
            self.repo / "README.md",
            self.docs,
            self.repo / "reproduce_paper.m",
        ):
            self.backup_path(p)

        method = r'''
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
'''
        write_text(self.docs / "METHOD.md", method)

        reproducibility = r'''
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
'''
        write_text(self.docs / "REPRODUCIBILITY.md", reproducibility)

        results_md = r'''
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
'''
        write_text(self.docs / "RESULTS.md", results_md)

        checklist = r'''
# Publication-Day Checklist

The implementation and paper-facing artifacts can remain frozen after the
release verifier passes.

Before creating the permanent paper tag:

- [ ] Add the public paper/preprint URL to `README.md`.
- [ ] Add the final BibTeX entry.
- [ ] Choose and add the intended source-code license, if not already done.
- [ ] Confirm the final paper-facing figures/tables match the submitted paper.
- [ ] Create `paper-v1.0`.

```bash
git tag -a paper-v1.0 -m "Paper companion code release"
git push origin paper-v1.0
```
'''
        write_text(self.docs / "RELEASE_CHECKLIST.md", checklist)

        hist_dir = self.docs / "development_history"
        hist_dir.mkdir(parents=True, exist_ok=True)
        for name in DOC_SOURCE_FILES:
            src = self.project / name
            if src.is_file():
                self.record_copy(src, hist_dir / name, "development_history")

        readme = r'''
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
'''
        self.backup_path(self.repo / "README.md")
        write_text(self.repo / "README.md", readme)

        reproduce = r'''
%REPRODUCE_PAPER Rebuild the final D-PACT-AFH communication-paper bundle.
clear functions
rehash
setup_paths

tic
final = run_complete_communication_rebuild("full"); %#ok<NASGU>
elapsedHours = toc / 3600;
fprintf("Full paper rebuild completed in %.3f hours.\n", elapsedHours);
'''
        write_text(self.repo / "reproduce_paper.m", reproduce)

    def write_release_scripts(self) -> None:
        print("\n[5/8] Write release verification scripts")

        scripts = self.repo / "scripts"
        scripts.mkdir(parents=True, exist_ok=True)

        verify_m = r'''
%VERIFY_RELEASE Fast non-destructive unit verification for the public release.
clear functions
rehash
setup_paths

tests = {
    'tests/current/test_attack_inclusion_probability_exact.m'
    'tests/current/test_dynamic_pact_exact.m'
    'tests/current/test_kl_hit_risk_projection_exact.m'
    'tests/current/test_reward_alignment_v2.m'
    'tests/current/test_fixed_size_attack_sampler.m'
    'tests/current/test_hybrid_expert_bank_v2.m'
};

for i = 1:numel(tests)
    fprintf('[TEST] %s\n', tests{i});
    run(tests{i});
end

disp('MATLAB_RELEASE_TESTS_PASS');
'''
        write_text(scripts / "verify_release.m", verify_m)

        verify_py = r'''#!/usr/bin/env python
from __future__ import annotations
from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[1]

REQUIRED = [
    "setup_paths.m",
    "learners/dynamic_pact_select.m",
    "learners/dynamic_pact_update.m",
    "experiments/communication/run_complete_communication_rebuild.m",
    "config/get_final_c1_c4_config.m",
    "results/paper_complete/full/COMPLETE_PAPER_MANIFEST.md",
    "docs/provenance/PUBLIC_SOURCE_MANIFEST.json",
]

missing = [p for p in REQUIRED if not (ROOT / p).is_file()]
if missing:
    print("FINAL_RELEASE_BLOCKED: missing files")
    for p in missing:
        print(" -", p)
    raise SystemExit(2)

bad_mat = list((ROOT / "results/paper_complete/full").rglob("*.mat"))
if bad_mat:
    print("FINAL_RELEASE_BLOCKED: MAT files in paper-facing release")
    for p in bad_mat:
        print(" -", p.relative_to(ROOT))
    raise SystemExit(2)

patterns = [
    re.compile(r"C:\\Users", re.I),
    re.compile(r"D:\\实验", re.I),
    re.compile(r"\bsk-[A-Za-z0-9_-]{16,}"),
    re.compile(r"\bgh[pousr]_[A-Za-z0-9]{20,}"),
]

hits = []
for base in [
    ROOT / "adversaries",
    ROOT / "config",
    ROOT / "core",
    ROOT / "diagnostics",
    ROOT / "env",
    ROOT / "experts",
    ROOT / "learners",
    ROOT / "metrics",
    ROOT / "plots",
    ROOT / "policies",
    ROOT / "tables",
    ROOT / "experiments/communication",
    ROOT / "tests/current",
    ROOT / "docs",
    ROOT / "README.md",
]:
    paths = [base] if base.is_file() else list(base.rglob("*"))
    for p in paths:
        if not p.is_file() or p.suffix.lower() not in {
            ".m", ".md", ".txt", ".csv", ".tex", ".json", ".py"
        }:
            continue
        text = p.read_text(encoding="utf-8-sig", errors="replace")
        for pattern in patterns:
            if pattern.search(text):
                hits.append(f"{p.relative_to(ROOT)} :: {pattern.pattern}")

if hits:
    print("FINAL_RELEASE_BLOCKED: path/secret scan")
    for hit in hits:
        print(" -", hit)
    raise SystemExit(2)

manifest = json.loads(
    (ROOT / "docs/provenance/PUBLIC_SOURCE_MANIFEST.json")
    .read_text(encoding="utf-8")
)

if not manifest.get("all_exact_copies", False):
    raise SystemExit("FINAL_RELEASE_BLOCKED: public source SHA audit failed")

print("STATIC_RELEASE_CHECKS_PASS")
print("FINAL_RELEASE_READY")
'''
        write_text(scripts / "verify_release.py", verify_py)

    def write_gitignore(self) -> None:
        print("\n[6/8] Write .gitignore")

        gitignore = r'''
# MATLAB generated files
*.asv
*.autosave
*.m~
slprj/
codegen/

# Large numerical artifacts / checkpoints
*.mat
*.fig
results/**
!results/paper_complete/
!results/paper_complete/full/
!results/paper_complete/full/COMPLETE_PAPER_MANIFEST.md
!results/paper_complete/full/figures/
!results/paper_complete/full/figures/**
!results/paper_complete/full/tables/
!results/paper_complete/full/tables/**

# Runtime / local state
tmp/
temp/
cache/
checkpoints/
logs/

# Python helper cache
__pycache__/
.pytest_cache/

# IDE / OS
.vscode/
.idea/
.DS_Store
Thumbs.db

# One-shot finalizer backups
_staging/
'''
        self.backup_path(self.repo / ".gitignore")
        write_text(self.repo / ".gitignore", gitignore)

    def provenance_and_static_checks(self) -> None:
        print("\n[7/8] Build provenance and run static checks")

        self.prov.mkdir(parents=True, exist_ok=True)

        all_exact = all(bool(row["exact_copy"]) for row in self.manifest_rows)
        write_text(
            self.prov / "PUBLIC_SOURCE_MANIFEST.json",
            json.dumps(
                {
                    "project": "D-PACT-AFH v3.8 communication release",
                    "policy": (
                        "Active MATLAB code and lightweight paper-facing "
                        "artifacts are copied byte-for-byte from the retained "
                        "v3.8 project. Raw MAT/checkpoint trees are excluded."
                    ),
                    "all_exact_copies": all_exact,
                    "files": self.manifest_rows,
                },
                indent=2,
                ensure_ascii=False,
            ),
        )

        if not all_exact:
            raise RuntimeError("At least one copied authoritative file changed")

        naming_errors: list[str] = []
        function_files = 0
        for path in self.repo.rglob("*.m"):
            if "_staging" in path.parts:
                continue
            fn = primary_matlab_function(path)
            if fn is None:
                continue
            function_files += 1
            if fn.lower() != path.stem.lower():
                naming_errors.append(
                    f"{path.relative_to(self.repo)} -> declares {fn}"
                )

        if naming_errors:
            raise RuntimeError(
                "MATLAB file/function naming mismatch:\n"
                + "\n".join(naming_errors)
            )

        scan_hits: list[str] = []
        scan_roots: list[Path] = [
            *(self.repo / name for name in ACTIVE_DIRS),
            self.repo / ACTIVE_EXPERIMENT_DIR,
            self.repo / ACTIVE_TEST_DIR,
            self.docs,
            self.repo / "README.md",
            self.repo / "reproduce_paper.m",
        ]

        for root in scan_roots:
            if not root.exists():
                continue
            candidates: Iterable[Path]
            if root.is_file():
                candidates = [root]
            else:
                candidates = (p for p in root.rglob("*") if p.is_file())

            for path in candidates:
                if path.suffix.lower() not in TEXT_EXTS:
                    continue
                text = path.read_text(encoding="utf-8-sig", errors="replace")
                for pattern in ABS_PATH_PATTERNS + SECRET_PATTERNS:
                    match = pattern.search(text)
                    if match:
                        scan_hits.append(
                            f"{path.relative_to(self.repo)} :: "
                            f"{match.group(0)[:80]}"
                        )

        if scan_hits:
            raise RuntimeError(
                "Public path/secret scan found hits:\n"
                + "\n".join(scan_hits)
            )

        figures = sorted(
            p.relative_to(self.repo).as_posix()
            for p in (self.repo / PAPER_RESULT_ROOT / "figures").glob("*")
            if p.is_file()
        )
        tables = sorted(
            p.relative_to(self.repo).as_posix()
            for p in (self.repo / PAPER_RESULT_ROOT / "tables").glob("*")
            if p.is_file()
        )

        audit = {
            "source_exact_copy": "PASS",
            "matlab_function_filename_audit": "PASS",
            "matlab_function_files_checked": function_files,
            "public_path_secret_scan": "CLEAN",
            "raw_mat_files_published": 0,
            "paper_figures": len(figures),
            "paper_tables": len(tables),
            "paper_figure_files": figures,
            "paper_table_files": tables,
        }

        self.release_checks = audit
        write_text(
            self.prov / "FINAL_RELEASE_AUDIT.json",
            json.dumps(audit, indent=2, ensure_ascii=False),
        )

        proc = run(
            [sys.executable, "scripts/verify_release.py"],
            self.repo,
        )
        if "FINAL_RELEASE_READY" not in proc.stdout:
            raise RuntimeError("Static release verifier did not pass")

        print(
            f"PASS: {function_files} MATLAB function files, "
            f"{len(figures)} figures, {len(tables)} table files"
        )

    def locate_matlab(self) -> Path | None:
        direct = shutil.which("matlab")
        if direct:
            return Path(direct)

        if os.name == "nt":
            base = Path(r"C:\Program Files\MATLAB")
            if base.is_dir():
                candidates = sorted(
                    base.glob(r"R20*\bin\matlab.exe"),
                    reverse=True,
                )
                if candidates:
                    return candidates[0]
        return None

    def maybe_run_matlab(self) -> None:
        print("\n[8/8] MATLAB execution check")

        matlab = self.locate_matlab()

        if not self.run_matlab:
            print("SKIPPED by default.")
            print("Run later in MATLAB: run('scripts/verify_release.m')")
            self.release_checks["matlab_execution"] = "NOT_REQUESTED"
        elif matlab is None:
            print("MATLAB executable not found; execution check skipped.")
            self.release_checks["matlab_execution"] = "SKIPPED_NOT_FOUND"
        else:
            repo_path = str(self.repo).replace("'", "''")
            expr = f"cd('{repo_path}'); run('scripts/verify_release.m');"
            proc = run(
                [str(matlab), "-batch", expr],
                self.repo,
                check=False,
            )
            if proc.returncode != 0 or "MATLAB_RELEASE_TESTS_PASS" not in proc.stdout:
                raise RuntimeError(
                    "MATLAB release tests failed. See command output above."
                )
            self.release_checks["matlab_execution"] = "PASS"
            print("MATLAB_RELEASE_TESTS_PASS")

        write_text(
            self.prov / "FINAL_RELEASE_AUDIT.json",
            json.dumps(
                self.release_checks,
                indent=2,
                ensure_ascii=False,
            ),
        )

    def finish(self) -> None:
        print("\n" + "=" * 68)
        print("ADAPTIVE FREQUENCY HOPPING PUBLIC REPOSITORY FINALIZED")
        print("=" * 68)
        print("Active MATLAB source      : PASS")
        print("Paper-facing artifacts    : PASS")
        print("Source SHA provenance     : PASS")
        print("MATLAB name audit         : PASS")
        print("Path/secret scan          : CLEAN")
        print("Multi-GB raw results      : EXCLUDED")
        print("Math-paper workspace      : EXCLUDED")
        print("Static release verifier   : FINAL_RELEASE_READY")
        print()
        print("Next in GitHub Desktop:")
        print("  1. Review Changes")
        print("  2. Summary: Finalize D-PACT-AFH paper companion repository")
        print("  3. Commit to main")
        print("  4. Push origin")
        print()
        print("Publication day only:")
        print('  git tag -a paper-v1.0 -m "Paper companion code release"')
        print("  git push origin paper-v1.0")

    def execute(self) -> None:
        self.validate()
        self.copy_active_source()
        self.copy_paper_artifacts()
        self.write_docs()
        self.write_release_scripts()
        self.write_gitignore()
        self.provenance_and_static_checks()
        self.maybe_run_matlab()
        self.finish()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project", default=PROJECT_DEFAULT)
    parser.add_argument("--repo", default=REPO_DEFAULT)
    parser.add_argument(
        "--run-matlab-tests",
        action="store_true",
        help=(
            "Run the fast MATLAB release tests if a MATLAB executable "
            "can be located. Default is static finalization only."
        ),
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        Finalizer(
            Path(args.project),
            Path(args.repo),
            args.run_matlab_tests,
        ).execute()
    except Exception as exc:
        print("\n" + "=" * 68)
        print("FINAL_RELEASE_BLOCKED")
        print("=" * 68)
        print(f"{type(exc).__name__}: {exc}")
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
