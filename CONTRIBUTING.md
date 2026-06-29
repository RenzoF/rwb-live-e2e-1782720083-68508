# Contributing to rwb-live-e2e-1782720083-68508

Issue-driven development on github (`github.com/RenzoF/rwb-live-e2e-1782720083-68508`).

## Workflow
1. Open & submit the issue using a template (Bug / Feature). The issue number is assigned on submit.
2. Note the issue number from the URL.
3. Create the branch off freshly-fetched `origin/main`:
   `git fetch origin && git checkout -b feat/<#>-short-slug origin/main`
   (or run **rwb-work-on-issue**).
4. Set the issue to `status/in-progress` when you start.
5. Open a PR whose body has `Closes #<#>` and an `## Acceptance criteria` checklist mirroring the
   issue's criteria, every box ticked.
6. Review -> merge. The forge auto-closes the issue on merge.

## The merge gate (`rwb-gate`)
A PR that closes an issue is blocked from merge by the required **criteria-gate** check
(`rwb-gate`, defined in `.github/workflows/rwb-gate.yml`) unless ALL of:
1. the PR body references a real, OPEN issue via `Closes/Fixes/Resolves #N`;
2. the PR body's `## Acceptance criteria` section is non-empty and EVERY box is ticked `[x]`;
3. that set matches the linked issue's acceptance criteria (order-insensitive).

> **All-AC-close constraint (important).** `Closes #N` closes the WHOLE issue, and the gate requires
> the PR to mirror ALL of that issue's acceptance criteria, all ticked. So a PR can only close an
> issue it **FULLY satisfies**. For partial work, split the issue or open a follow-up issue for the
> remainder rather than partially closing one — there is deliberately no partial-close mechanism.

> **Re-triggering the gate.** Ticking AC checkboxes by editing the PR body fires the `edited` event,
> which re-runs the gate (verified on this Gitea). If a run is ever stuck, push an empty/synchronising
> commit; never use `workflow_dispatch` — a dispatched run carries no PR payload and can never
> satisfy the required check.

### Skills (Claude-assisted)
The daily loop is wrapped by four committed skills (see `docs/skills-quickref.md`):
- **rwb-create-issue** — author a structured issue with `## Acceptance criteria`.
- **rwb-work-on-issue `<#>`** — branch `<kind>/<#>-<slug>` + `status/in-progress`.
- **rwb-commit** — issue-aware Conventional Commit (stages by name, no secrets).
- **rwb-create-pr** — mirror + tick the issue's AC into the PR body, open `Closes #N`.

## Branch naming
`<kind>/<issue#>-<slug>`, `kind` in {feat, fix, hotfix, chore, docs} — the translation of the
`type/*` label: `type/bug`->`fix`, `type/feature`->`feat`, `type/chore`->`chore`, `type/docs`->`docs`.

## Commits
[Conventional Commits](https://www.conventionalcommits.org/): `type(scope): subject`.

## Merge strategy
- **Squash-merge** feature branches (keeps `main` history readable).
- **Merge-commit** hotfixes.

## Solo vs team mode
In **solo mode** no non-author review is required, so a lone owner is never locked out; the gate is
still a real self-discipline gate. In **team mode** a non-author review is required and CODEOWNERS
makes gate-critical paths (`.github/workflows/rwb-gate.yml`, `CODEOWNERS`, `scripts/rwb-ac-check.sh`) require
owner sign-off. A single code owner in team mode deadlocks the recurring bootstrap-sync PR — if you
are effectively one person, choose solo mode.

## CODEOWNERS
On github, CODEOWNERS is routing-only unless the branch-protection rule enables code-owner review
(Gitea 1.25.4 has no code-owner-enforcement field -> routing-only; team-mode review rests on required
approvals). See repo settings under `https://github.com`.
<!-- rwb-managed:v1 sha256=629b2e0326f4e551e38edd977f52f390da4e5b685424a131669db3f0bfca106e -->
