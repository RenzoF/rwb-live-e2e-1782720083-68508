#!/usr/bin/env sh
# rwb-ac-check.sh — repo-workflow-bootstrap criteria-gate AC checker (forge-neutral; Gitea + GitHub).
# Rendered into the target repo at scripts/rwb-ac-check.sh and invoked by
# the criteria-gate workflow on each forge (.gitea/workflows/rwb-gate.yml and
# .github/workflows/rwb-gate.yml, job gate). POSIX sh / busybox-ash safe.
#
# Pinned criteria-gate pass-condition (conditions 1-3):
#   (1) PR TITLE or BODY references a real, OPEN issue via Closes/Fixes/Resolves #N.
#   (2) The PR body Acceptance-Criteria checklist is NON-EMPTY and EVERY box ticked.
#   (3) The PR AC item set (normalized: trimmed + ws-collapsed; order-insensitive)
#       SET-MATCHES the linked issue's AC set (extra or missing => fail + diff).
# Fails CLOSED (exit 1) if invoked without a resolvable pull_request payload (#14).
#
# AC-section delimiter (single source of truth, reused by the PR/issue templates):
#   start: ATX heading, any level, case-insensitive  /^#+[[:space:]]*acceptance criteria/
#   end:   next ATX heading of any level             /^#+[[:space:]]/
#
# Runtime env (Gitea Actions auto-provides): GITHUB_EVENT_PATH, GITHUB_API_URL,
#   GITHUB_REPOSITORY; GITHUB_TOKEN is mapped into the step by the workflow.
# Offline test seam (NO network): RWB_EVENT_PATH overrides GITHUB_EVENT_PATH;
#   RWB_ISSUE_JSON points to the issue GET response ({state,body}) and, when set,
#   the API fetch is skipped entirely.
#
# Exit: 0 pass; 1 gate fail / no-payload; 2 operational error.
set -u
LC_ALL=C; export LC_ALL

# Checkbox-marker grammar — single source of truth for the four sites that scan Markdown
# task-list items ("- [ ]" / "* [x]" / "+ [X]"). Each site appends its own bracket class
# (e.g. "[ xX]\]") so the bullet/whitespace prefix has ONE definition.
RWB_CB='^[[:space:]]*[-*+][[:space:]]+\['

RWB_TMP="$(mktemp -d)"
trap 'rm -rf "$RWB_TMP"' EXIT INT TERM

fail() { printf 'GATE FAIL: %s\n' "$1" >&2; exit 1; }
oops() { printf 'GATE ERROR: %s\n' "$1" >&2; exit 2; }

for _c in jq awk grep sed sort comm curl; do
  command -v "$_c" >/dev/null 2>&1 || oops "required command not found: $_c"
done

_ac_section() {  # <markdown-body> -> the AC section lines
  printf '%s\n' "$1" | awk '
    tolower($0) ~ /^#+[[:space:]]*acceptance criteria/ { insec = 1; next }
    insec && /^#+[[:space:]]/                          { insec = 0 }
    insec                                              { print }
  '
}
_ac_items() {  # <ac-section> -> normalized, de-duplicated, sorted item texts
  printf '%s\n' "$1" \
    | grep -E "${RWB_CB}[ xX]\]" \
    | sed -E "s/${RWB_CB}[ xX]\][[:space:]]*//; s/[[:space:]]+/ /g; s/^ //; s/ \$//" \
    | awk 'NF' \
    | sort -u
}

_fetch_issue() {  # <num> -> JSON on stdout; rc 0=200 1=404 2=error
  _num="$1"
  _api="${GITHUB_API_URL:-${GITEA_API_URL:-}}"
  _repo="${GITHUB_REPOSITORY:-}"
  _tok="${GITHUB_TOKEN:-${GITEA_TOKEN:-}}"
  if [ -z "$_api" ] || [ -z "$_repo" ] || [ -z "$_tok" ]; then
    printf 'missing GITHUB_API_URL/GITHUB_REPOSITORY/GITHUB_TOKEN\n' >&2; return 2
  fi
  case "$_api" in https://*) : ;; *) printf 'refusing non-https API base: %s\n' "$_api" >&2; return 2 ;; esac
  _xt=0; case $- in *x*) _xt=1; set +x ;; esac
  _code="$(curl -sS --config - -o "$RWB_TMP/issue.json" -w '%{http_code}' \
      "${_api}/repos/${_repo}/issues/${_num}" <<EOF || echo 000
header = "Authorization: token ${_tok}"
EOF
)"
  [ "$_xt" = 1 ] && set -x
  if [ "$_code" = "200" ]; then cat "$RWB_TMP/issue.json"; return 0; fi
  [ "$_code" = "404" ] && return 1
  printf 'GET issue #%s returned HTTP %s\n' "$_num" "$_code" >&2
  return 2
}

EVENT_PATH="${RWB_EVENT_PATH:-${GITHUB_EVENT_PATH:-}}"
{ [ -n "$EVENT_PATH" ] && [ -f "$EVENT_PATH" ]; } || fail "no event payload file (fail-closed)"
PR_TITLE="$(jq -r '.pull_request.title // empty' "$EVENT_PATH" 2>/dev/null || true)"
PR_BODY="$(jq -r '.pull_request.body // empty' "$EVENT_PATH" 2>/dev/null || true)"
PR_NUMBER="$(jq -r '.pull_request.number // empty' "$EVENT_PATH" 2>/dev/null || true)"
[ -n "$PR_NUMBER" ] || fail "event payload carries no .pull_request (fail-closed)"

ISSUE_NUM="$(printf '%s\n%s\n' "$PR_TITLE" "$PR_BODY" | awk '
  {
    line = tolower($0)
    while (match(line, /(close[sd]?|fix(es|ed)?|resolve[sd]?):?[ \t]+#[0-9]+/)) {
      tok = substr(line, RSTART, RLENGTH); sub(/^.*#/, "", tok); print tok
      line = substr(line, RSTART + RLENGTH)
    }
  }' | head -1)"
[ -n "$ISSUE_NUM" ] || fail "no Closes/Fixes/Resolves #N reference in PR title or body (condition 1)"

if [ -n "${RWB_ISSUE_JSON:-}" ]; then
  [ -f "$RWB_ISSUE_JSON" ] || oops "RWB_ISSUE_JSON points to a missing file: $RWB_ISSUE_JSON"
  ISSUE_RESP="$(cat "$RWB_ISSUE_JSON")"
else
  ISSUE_RESP="$(_fetch_issue "$ISSUE_NUM")"; _rc=$?
  case "$_rc" in
    0) : ;;
    1) fail "linked issue #$ISSUE_NUM does not exist (condition 1)" ;;
    *) oops "could not fetch issue #$ISSUE_NUM" ;;
  esac
fi
ISSUE_STATE="$(printf '%s' "$ISSUE_RESP" | jq -r '.state // empty' 2>/dev/null || true)"
[ "$ISSUE_STATE" = "open" ] || fail "linked issue #$ISSUE_NUM is not OPEN (state=${ISSUE_STATE:-unknown}) (condition 1)"
ISSUE_BODY="$(printf '%s' "$ISSUE_RESP" | jq -r '.body // ""' 2>/dev/null || true)"

PR_SECTION="$(_ac_section "$PR_BODY")"
[ -n "$(printf '%s' "$PR_SECTION" | tr -d '[:space:]')" ] \
  || fail "PR body has no non-empty Acceptance Criteria section (condition 2)"
PR_BOXES="$(printf '%s\n' "$PR_SECTION" | grep -E "${RWB_CB}[ xX]\]" || true)"
[ -n "$PR_BOXES" ] || fail "PR Acceptance Criteria section has no checkboxes (condition 2)"
PR_UNCHECKED="$(printf '%s\n' "$PR_SECTION" | grep -E "${RWB_CB}[[:space:]]\]" || true)"
[ -z "$PR_UNCHECKED" ] || fail "PR has unticked Acceptance Criteria boxes (condition 2):
$PR_UNCHECKED"

ISSUE_ITEMS="$(_ac_items "$(_ac_section "$ISSUE_BODY")")"
PR_ITEMS="$(_ac_items "$PR_SECTION")"
[ -n "$ISSUE_ITEMS" ] || fail "linked issue #$ISSUE_NUM has no Acceptance Criteria checklist (condition 3)"
printf '%s\n' "$ISSUE_ITEMS" > "$RWB_TMP/issue.items"
printf '%s\n' "$PR_ITEMS"    > "$RWB_TMP/pr.items"
MISSING="$(comm -23 "$RWB_TMP/issue.items" "$RWB_TMP/pr.items")"
EXTRA="$(comm -13 "$RWB_TMP/issue.items" "$RWB_TMP/pr.items")"
if [ -n "$MISSING" ] || [ -n "$EXTRA" ]; then
  _m="PR Acceptance Criteria do not set-match linked issue #$ISSUE_NUM (condition 3)"
  [ -n "$MISSING" ] && _m="$_m
  missing from PR (present in issue):
$(printf '%s\n' "$MISSING" | sed 's/^/    - /')"
  [ -n "$EXTRA" ] && _m="$_m
  extra in PR (absent from issue):
$(printf '%s\n' "$EXTRA" | sed 's/^/    - /')"
  fail "$_m"
fi

_n="$(printf '%s\n' "$PR_ITEMS" | awk 'NF' | wc -l | tr -d ' ')"
printf 'GATE PASS: issue #%s open; %s AC item(s) set-matched and all ticked\n' "$ISSUE_NUM" "$_n"
exit 0
