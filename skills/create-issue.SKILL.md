---
name: rwb-create-issue
description: Use when the user wants to file, open, or create an issue (bug/feature/chore/docs) in the RenzoF/rwb-live-e2e-1782720083-68508 repo on github.com. Authors a well-structured issue with the repo's scoped labels and template shape, including an Acceptance criteria checklist. NEVER implements code — only creates the issue.
---

# rwb-create-issue

Interactively author a well-structured issue for **RenzoF/rwb-live-e2e-1782720083-68508** and create it. Run from inside the
repo checkout.

## Absolute rules
- This skill ONLY creates an issue. It never writes code or branches.
- Use the EXACT scoped label names (below). Never invent labels.
- Every issue gets an `## Acceptance criteria` checklist of `- [ ]` items — it is what the
  criteria-gate (`rwb-gate`) enforces when a PR later closes the issue, and a PR can only close an
  issue when it satisfies ALL of that issue's criteria (see CONTRIBUTING).

## Labels (exact, verbatim)
- type: `type/bug` `type/feature` `type/chore` `type/docs`
- priority: `priority/P0-urgent` `priority/P1-high` `priority/P2-medium` `priority/P3-low`
- status: always `status/triage` on a new issue.

## Step 0 — One issue or several?
If the report describes several distinct problems, list them back and confirm before filing each
separately. Don't over-split symptoms of one bug.

## Step 1 — Type
From the user's words or ask: bug / feature / chore / docs.

## Step 2 — Gather (one question at a time, multiple-choice where possible)
- **Bug:** where (page/module) · current vs expected · reproducibility · severity -> `priority/*`.
- **Feature:** problem/motivation · proposed solution · where (module) · acceptance criteria.
- **Chore/docs:** what + why · acceptance criteria.

## Step 3 — Build the body to match the template shape
British spelling (`behaviour`). Headings are level-2 `##`. Always include `## Acceptance criteria`
with concrete `- [ ]` items.

## Step 4 — Confirm, then create
Show the title + body + labels for approval. Build the body with a **QUOTED heredoc** so newlines and
the `- [ ]` checklist survive verbatim (do NOT use `printf '%s'` with `\n` escapes — they collapse
the checklist the gate depends on):

```bash
BODY=$(cat <<'EOF'
## Description
…

## Acceptance criteria
- [ ] first criterion
- [ ] second criterion
EOF
)
tea issues create -t "<title>" -d "$BODY" -L "type/<x>,priority/<y>,status/triage"
```
`tea` must be logged in to github.com. Without `tea`, resolve label NAMES to IDs first (the REST
`labels` field takes IDs), then POST to `https://api.github.com/repos/RenzoF/rwb-live-e2e-1782720083-68508/issues` with a JSON body —
token read-only from the env/`tea` config, never echoed.

Report the new issue number + URL.

## Step 5 — Next step
Tell the user they can run **rwb-work-on-issue <#>** to branch off and start.
<!-- rwb-managed:v1 sha256=5578202bb5a5ebfad4dad710ca12c6697ad713038f26fd5e29491b9c34d851e9 -->
