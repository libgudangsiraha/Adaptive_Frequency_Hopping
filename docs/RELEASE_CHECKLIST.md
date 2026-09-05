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
