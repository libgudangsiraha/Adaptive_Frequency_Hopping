# v3.8 complete rebuild

- Recognizes that deleted old result packages cannot be redrawn.
- Retains the current source code and reruns missing experiments.
- Replaces legacy `bc_*` C2/C4 with final D-PACT C2/C4 runners.
- Adds D-PACT-Safe95 directly to common-seed C2 and C3 comparisons.
- Adds final LC-only / Local-only / Base / Hit / Safe C4 ablation.
- Adds one resumable C1-C6 rebuild command.
- Exports final C2-C4 figures to 300-dpi PNG and vector PDF.
- Reuses current full model-probe and C5 results when present.
- Does not change the frozen learner mathematics.
