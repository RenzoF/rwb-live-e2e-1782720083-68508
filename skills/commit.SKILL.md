---
name: rwb-commit
description: Use when committing staged or unstaged work on a RenzoF/rwb-live-e2e-1782720083-68508 issue branch — writes a Conventional Commit, stages only relevant files by name, and does a light sanity-check against the linked issue. For the github.com/RenzoF/rwb-live-e2e-1782720083-68508 repo.
---

# rwb-commit

Create a clean Conventional Commit for work on an issue branch. Run from the repo root.

## Step 1 — Understand the changes
```bash
git branch --show-current
git status
git diff            # unstaged
git diff --staged   # staged
git log --oneline -5
```
If the current branch is `main`, warn the user — work belongs on an issue branch
(`<kind>/<#>-<slug>`, see **rwb-work-on-issue**). Only commit to `main`
if they explicitly confirm.

## Step 2 — Linked issue (light sanity-check)
Parse the issue number `<#>` from the branch (`<kind>/<#>-<slug>`). If found, fetch the issue (token
read-only from env/`tea` config — never echo it) and check the changes plausibly relate to it;
flag clearly-unrelated changes and ask whether they belong here, in a separate commit, or a separate
issue. If the branch has no issue number, skip this check.
```bash
TOKEN="${GITEA_TOKEN:-$(grep -hE '^[[:space:]]+token:' \
  "${XDG_CONFIG_HOME:-$HOME/.config}/tea/config.yml" \
  "$HOME/Library/Application Support/tea/config.yml" 2>/dev/null | head -1 | \
  sed -E 's/^[[:space:]]*token:[[:space:]]*//')}"
curl -s --config - "https://api.github.com/repos/RenzoF/rwb-live-e2e-1782720083-68508/issues/<#>" <<EOF | jq -r '{number, title, labels: [.labels[].name], state}'
header = "Authorization: token ${TOKEN}"
EOF
```

## Step 3 — Stage relevant files BY NAME
- Never `git add -A` / `git add .`.
- Never stage secrets (`.env`, credentials, tokens, `*.key`).
- Stage only the files that belong to this change.

## Step 4 — Write the Conventional Commit
`type(scope): subject` — type in feat|fix|docs|refactor|chore|test|ci. First line imperative, <=72
chars (e.g. `fix(cin7): handle null receiveddate`). If changes span unrelated concerns, suggest
splitting into multiple commits.
```bash
git commit -m "$(cat <<'EOF'
type(scope): subject
EOF
)"
```

## Step 5 — Verify, do not push
Run `git status` to confirm. Do NOT push unless the user asks (the PR is opened later via
**rwb-create-pr**).
<!-- rwb-managed:v1 sha256=7b2727b7cbe2ee43e1852232f04dac438f907bbab4fb897f585646dc8e1a215f -->
