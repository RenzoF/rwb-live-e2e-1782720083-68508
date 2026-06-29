# Skills quick reference — RenzoF/rwb-live-e2e-1782720083-68508

The issue -> branch -> commit -> PR loop, wrapped by four committed skills. Invoke by intent or name.

| Skill | When | What it does |
|-------|------|--------------|
| `rwb-create-issue` | filing a bug/feature/chore/docs | authors a structured issue with scoped labels + `## Acceptance criteria` |
| `rwb-work-on-issue <#>` | starting work | branch `<kind>/<#>-<slug>` off `origin/main` + `status/in-progress` |
| `rwb-commit` | committing | issue-aware Conventional Commit, stages by name, no secrets |
| `rwb-create-pr` | opening the PR | mirrors + ticks the issue's AC into the PR body, opens `Closes #N` |

## The loop
1. `rwb-create-issue` -> note `#N`.
2. `rwb-work-on-issue N`.
3. work, then `rwb-commit` (repeat as needed).
4. `rwb-create-pr` -> review -> merge (the `rwb-gate` check must be green).

See `CONTRIBUTING.md` for the full gate rules and the all-AC-close constraint.
<!-- rwb-managed:v1 sha256=7b8b67fc66c7206019ecd6db6fdc0492a5bb523ab6ae7b722068af5c7dc74f28 -->
