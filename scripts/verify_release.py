#!/usr/bin/env python
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
