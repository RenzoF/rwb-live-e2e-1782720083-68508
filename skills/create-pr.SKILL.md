---
name: rwb-create-pr
description: "Use when opening a pull request for the current RenzoF/rwb-live-e2e-1782720083-68508 issue branch — validates the linked issue's acceptance criteria, mirrors them (all ticked) into the PR body, then opens the PR with Closes #N. For the github.com/RenzoF/rwb-live-e2e-1782720083-68508 repo."
---

# rwb-create-pr

Validate the work against the linked issue, then open the PR. Run from the repo root.

## Absolute rule (matches the `rwb-gate` criteria-gate)
The PR BODY must contain a `## Acceptance criteria` section that **mirrors the linked issue's
acceptance criteria, every box ticked `[x]`**, plus `Closes #N` to a real OPEN issue. The gate
(`rwb-gate`) requires: the issue is real + open; the PR-body AC is non-empty and fully ticked; and
that set matches the issue's AC (order-insensitive). A PR closes an issue only when it satisfies ALL
of its AC — for partial work, split the issue or open a follow-up.

## Step 1 — Gather context
```bash
git branch --show-current
git status
git log main..HEAD --oneline
git diff main...HEAD --stat
```
Parse the issue number from the branch. If none, ask which issue it addresses.

## Step 2 — Fetch the issue + judge each criterion
```bash
TOKEN="${GITEA_TOKEN:-$(grep -hE '^[[:space:]]+token:' \
  "${XDG_CONFIG_HOME:-$HOME/.config}/tea/config.yml" \
  "$HOME/Library/Application Support/tea/config.yml" 2>/dev/null | head -1 | \
  sed -E 's/^[[:space:]]*token:[[:space:]]*//')}"
curl -s --config - "https://api.github.com/repos/RenzoF/rwb-live-e2e-1782720083-68508/issues/<#>" <<EOF | jq -r '.body'
header = "Authorization: token ${TOKEN}"
EOF
```
For each `## Acceptance criteria` item, judge it against `git diff main...HEAD`:
met / partial / not-addressed / cannot-verify.

## Step 3 — Build the PR body: mirror the issue AC, all ticked
Copy the linked issue's AC items VERBATIM into a `## Acceptance criteria` section of the PR body and
tick each `[x]`. Then preview exactly what the gate's checker will score, using its offline seam
(`RWB_EVENT_PATH` for the event payload + `RWB_ISSUE_JSON` for the linked issue, so the checker makes
no network call of its own — same seam as the gate's tests). Replace `<#>` with the real issue number
first:
```bash
PR_BODY=$(cat <<'EOF'
Closes #<#>

## Acceptance criteria
- [x] criterion one (verbatim from issue, ticked)
- [x] criterion two
EOF
)
jq -n --arg b "$PR_BODY" '{pull_request:{number:0,title:"",body:$b}}' > /tmp/rwb-ev.json
curl -s --config - "https://api.github.com/repos/RenzoF/rwb-live-e2e-1782720083-68508/issues/<#>" > /tmp/rwb-issue.json <<EOF
header = "Authorization: token ${TOKEN}"
EOF
RWB_EVENT_PATH=/tmp/rwb-ev.json RWB_ISSUE_JSON=/tmp/rwb-issue.json sh scripts/rwb-ac-check.sh
```
- exit 0 -> `GATE PASS` (Closes #N resolves to an open issue; PR AC non-empty, fully ticked, set-matches the issue).
- exit 1 -> gate fail; it prints the offending condition (missing `Closes #N`, unticked boxes, or an AC set-mismatch) — fix before merge.
- exit 2 -> operational error (fix before proceeding).
If any criterion is genuinely not done, do NOT fabricate a tick: split it to a follow-up issue and
remove it from the closing issue's AC, or keep the PR non-closing.

## Step 4 — Push and open the PR
```bash
git push -u origin "$(git branch --show-current)"
tea pulls create --head "$(git branch --show-current)" --base main \
  -t "<conventional title>" -d "$PR_BODY"
```
`$PR_BODY` must start with `Closes #<#>` and contain the mirrored, fully-ticked `## Acceptance
criteria` section. If a PR already exists for this branch, surface it instead of creating a duplicate.

## Step 5 — Merge strategy (inform; leave the merge to the human)
- Feature branches: **squash-merge** (Closes #N in the body still auto-closes the issue).
- Hotfixes: **merge-commit**.
State that the `rwb-gate` check must be green before merge.

> **Re-triggering the gate:** ticking AC boxes by editing the PR body fires `edited`, which re-runs
> the gate (verified on this Gitea). If ever stuck, push an empty/synchronising commit — never
> `workflow_dispatch`.
<!-- rwb-managed:v1 sha256=42648f4081890483f2a17e2cd099d69efca2bab8a5a1727cbb1e206f95206ee9 -->
