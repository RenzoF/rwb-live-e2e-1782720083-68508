---
name: rwb-work-on-issue
description: Use when starting work on a RenzoF/rwb-live-e2e-1782720083-68508 issue — given an issue number, creates the convention branch (<kind>/<issue#>-<slug>) off origin/main and flips the issue to status/in-progress. For the github.com/RenzoF/rwb-live-e2e-1782720083-68508 repo.
---

# rwb-work-on-issue

Given an issue number, create its branch and mark it in-progress. Run from inside the repo checkout.

## Step 1 — Get the issue
If a number was given, fetch it; else list open issues by priority and ask which. Token read-only
from env `GITEA_TOKEN` else the `tea` config; never echo it.

```bash
TOKEN="${GITEA_TOKEN:-$(grep -hE '^[[:space:]]+token:' \
  "${XDG_CONFIG_HOME:-$HOME/.config}/tea/config.yml" \
  "$HOME/Library/Application Support/tea/config.yml" 2>/dev/null | head -1 | \
  sed -E 's/^[[:space:]]*token:[[:space:]]*//')}"
curl -s --config - "https://api.github.com/repos/RenzoF/rwb-live-e2e-1782720083-68508/issues/<#>" <<EOF | jq -r '{number, title, labels: [.labels[].name], state}'
header = "Authorization: token ${TOKEN}"
EOF
```

## Step 2 — Determine branch kind (translate the type label; do NOT use the label noun)
- `type/bug` -> `fix`
- `type/feature` -> `feat`   (NOT `feature` — that prefix is deprecated)
- `type/chore` -> `chore`
- `type/docs` -> `docs`
- **No `type/*` label?** Ask the user which kind (default `chore` for housekeeping, `feat` for new
  work) and add the matching `type/*` label.
- **`hotfix`** only if the issue is `priority/P0-urgent` AND it's an urgent production fix — confirm.

## Step 3 — Build the branch name
`<kind>/<issue#>-<slug>` where slug = 3–5 words from the title, lowercase, hyphen-separated, ASCII.
Example: issue #42 "Cin7 kit import drops components" (type/bug) -> `fix/42-cin7-kit-import`.

## Step 4 — Create the branch off freshly-fetched origin/main
```bash
git fetch origin
git checkout -b <kind>/<#>-<slug> origin/main
```
- If the branch already exists: offer `git checkout <branch>` instead of recreating.
- If the working tree is dirty: warn and let the user stash/commit first.

## Step 5 — Flip the issue to in-progress
```bash
tea issues edit <#> --add-labels status/in-progress \
  --remove-labels status/triage,status/blocked,status/done,status/wont-fix
```
(`status/*` labels are exclusive; remove every other `status/*` to enforce the invariant.)

## Step 6 — Report
State the branch you're on and that work can begin. Suggest **rwb-commit** when ready.
<!-- rwb-managed:v1 sha256=3800f70ed72ede76a89dadbb4d18ebe7806c4695b2b91c5965562ab9e4cfe1aa -->
