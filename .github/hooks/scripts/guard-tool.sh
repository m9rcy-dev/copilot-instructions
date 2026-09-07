#!/usr/bin/env bash
# preToolUse hook: fail-closed guard against destructive shell commands
# (hard resets, force pushes, rm -rf, DB drops, chmod 777, curl|bash,
# sudo, npm publish) before ANY shell tool call goes through — not
# scoped to `git commit` like scan-secrets-pretooluse.sh and
# quality-gate-pretooluse.sh, since a `git reset --hard` or `rm -rf` can
# do irreversible damage outside a commit entirely.
#
# Adapted from github/awesome-copilot's tool-guardian hook
# (https://github.com/github/awesome-copilot/tree/main/hooks/tool-guardian,
# MIT licensed) with two changes to match how THIS repo's other
# preToolUse hooks actually read Copilot's hook input and signal a
# block, rather than upstream's own assumptions:
#   - reads `.tool_input.command // .command` (same as the other two
#     hooks here), not upstream's `.toolName` / `.toolInput` fields.
#   - blocks by exiting 2, not upstream's exit 1 — this repo documents
#     (see copilot-setup-handoff.md) that Copilot CLI's preToolUse
#     fail-closed signal is exit 2.
# Neither convention has been verified against a live Copilot CLI
# install (see the README's existing caveat on hook schema) — if hooks
# don't fire as expected, that's the first thing to check.
#
# Environment variables:
#   GUARD_MODE           - "warn" (log only) or "block" (exit 2 on threats) (default: block)
#   SKIP_TOOL_GUARD       - "true" to disable entirely (default: unset)
#   TOOL_GUARD_LOG_DIR    - Directory for guard logs (default: .github/hooks/.audit-log)
#   TOOL_GUARD_ALLOWLIST  - Comma-separated substrings to skip (default: unset)
#
# Requires: jq (same requirement as the other preToolUse hooks in this repo).

set -uo pipefail

if [[ "${SKIP_TOOL_GUARD:-}" == "true" ]]; then
  exit 0
fi

input="$(cat)"
command_str="$(echo "$input" | jq -r '.tool_input.command // .command // empty' 2>/dev/null || true)"

if [[ -z "$command_str" ]]; then
  exit 0
fi

MODE="${GUARD_MODE:-block}"
LOG_DIR="${TOOL_GUARD_LOG_DIR:-.github/hooks/.audit-log}"
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
cd "$repo_root" || exit 0

mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/tool-guardian-$(date +%Y%m%d).log"

# ---------------------------------------------------------------------------
# Parse allowlist — comma-separated substrings; a match skips all scanning
# ---------------------------------------------------------------------------
ALLOWLIST=()
if [[ -n "${TOOL_GUARD_ALLOWLIST:-}" ]]; then
  IFS=',' read -ra ALLOWLIST <<< "$TOOL_GUARD_ALLOWLIST"
fi

is_allowlisted() {
  local text="$1"
  for pattern in "${ALLOWLIST[@]}"; do
    pattern="$(printf '%s' "$pattern" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [[ -z "$pattern" ]] && continue
    if [[ "$text" == *"$pattern"* ]]; then
      return 0
    fi
  done
  return 1
}

if [[ ${#ALLOWLIST[@]} -gt 0 ]] && is_allowlisted "$command_str"; then
  printf '{"timestamp":"%s","event":"guard_skipped","reason":"allowlisted","command":"%s"}\n' \
    "$TIMESTAMP" "$(printf '%s' "$command_str" | sed 's/\\/\\\\/g; s/"/\\"/g')" >> "$LOG_FILE"
  exit 0
fi

# ---------------------------------------------------------------------------
# Threat patterns (6 categories, ~20 patterns) — verbatim from upstream
# tool-guardian; each entry: "CATEGORY:::SEVERITY:::REGEX:::SUGGESTION"
# ---------------------------------------------------------------------------
PATTERNS=(
  # Destructive file operations
  "destructive_file_ops:::critical:::rm -rf /:::Use targeted 'rm' on specific paths instead of root"
  "destructive_file_ops:::critical:::rm -rf ~:::Use targeted 'rm' on specific paths instead of home directory"
  "destructive_file_ops:::critical:::rm -rf \.:::Use targeted 'rm' on specific files instead of current directory"
  "destructive_file_ops:::critical:::rm -rf \.\.:::Never remove parent directories recursively"
  "destructive_file_ops:::critical:::(rm|del|unlink).*\.env:::Use 'mv' to back up .env files before removing"
  "destructive_file_ops:::critical:::(rm|del|unlink).*\.git[^i]:::Never delete .git directory — use 'git' commands to manage repo state"

  # Destructive git operations
  "destructive_git_ops:::critical:::git push --force.*(main|master):::Use 'git push --force-with-lease' or push to a feature branch"
  "destructive_git_ops:::critical:::git push -f.*(main|master):::Use 'git push --force-with-lease' or push to a feature branch"
  "destructive_git_ops:::high:::git reset --hard:::Use 'git stash' to preserve changes, or 'git reset --soft'"
  "destructive_git_ops:::high:::git clean -fd:::Use 'git clean -n' (dry run) first to preview what will be deleted"

  # Database destruction
  "database_destruction:::critical:::DROP TABLE:::Use 'ALTER TABLE' or create a migration with rollback support"
  "database_destruction:::critical:::DROP DATABASE:::Create a backup first; consider revoking DROP privileges"
  "database_destruction:::critical:::TRUNCATE:::Use 'DELETE FROM ... WHERE' with a condition for safer data removal"
  "database_destruction:::high:::DELETE FROM [a-zA-Z_]+ *;:::Add a WHERE clause to 'DELETE FROM' to avoid deleting all rows"

  # Permission abuse
  "permission_abuse:::high:::chmod 777:::Use 'chmod 755' for directories or 'chmod 644' for files"
  "permission_abuse:::high:::chmod -R 777:::Use specific permissions ('chmod -R 755') and limit scope"

  # Network exfiltration
  "network_exfiltration:::critical:::curl.*\|.*bash:::Download the script first, review it, then execute"
  "network_exfiltration:::critical:::wget.*\|.*sh:::Download the script first, review it, then execute"
  "network_exfiltration:::high:::curl.*--data.*@:::Review what data is being sent before using 'curl --data @file'"

  # System danger
  "system_danger:::high:::sudo :::Avoid 'sudo' — run commands with the least privilege needed"
  "system_danger:::high:::npm publish:::Use 'npm publish --dry-run' first to verify package contents"
)

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

THREATS=()
THREAT_COUNT=0

for entry in "${PATTERNS[@]}"; do
  category="${entry%%:::*}"
  rest="${entry#*:::}"
  severity="${rest%%:::*}"
  rest="${rest#*:::}"
  regex="${rest%%:::*}"
  suggestion="${rest#*:::}"

  if printf '%s\n' "$command_str" | grep -qiE "$regex" 2>/dev/null; then
    match="$(printf '%s\n' "$command_str" | grep -oiE "$regex" 2>/dev/null | head -1)"
    THREATS+=("${category}	${severity}	${match}	${suggestion}")
    THREAT_COUNT=$((THREAT_COUNT + 1))
  fi
done

if [[ $THREAT_COUNT -gt 0 ]]; then
  echo ""
  echo "Tool Guardian: $THREAT_COUNT threat(s) detected in this command"
  echo ""
  printf "  %-24s %-10s %-40s %s\n" "CATEGORY" "SEVERITY" "MATCH" "SUGGESTION"
  printf "  %-24s %-10s %-40s %s\n" "--------" "--------" "-----" "----------"

  FINDINGS_JSON="["
  FIRST=true
  for threat in "${THREATS[@]}"; do
    IFS=$'\t' read -r category severity match suggestion <<< "$threat"

    display_match="$match"
    if [[ ${#match} -gt 38 ]]; then
      display_match="${match:0:35}..."
    fi
    printf "  %-24s %-10s %-40s %s\n" "$category" "$severity" "$display_match" "$suggestion"

    if [[ "$FIRST" != "true" ]]; then
      FINDINGS_JSON+=","
    fi
    FIRST=false
    FINDINGS_JSON+="{\"category\":\"$(json_escape "$category")\",\"severity\":\"$(json_escape "$severity")\",\"match\":\"$(json_escape "$match")\",\"suggestion\":\"$(json_escape "$suggestion")\"}"
  done
  FINDINGS_JSON+="]"

  echo ""

  printf '{"timestamp":"%s","event":"threats_detected","mode":"%s","threat_count":%d,"threats":%s}\n' \
    "$TIMESTAMP" "$MODE" "$THREAT_COUNT" "$FINDINGS_JSON" >> "$LOG_FILE"

  if [[ "$MODE" == "block" ]]; then
    echo "BLOCKED: resolve the threats above or adjust TOOL_GUARD_ALLOWLIST." >&2
    echo "Set GUARD_MODE=warn to log without blocking." >&2
    exit 2
  else
    echo "Threats logged in warn mode. Set GUARD_MODE=block to prevent these operations."
  fi
else
  printf '{"timestamp":"%s","event":"guard_passed","mode":"%s"}\n' \
    "$TIMESTAMP" "$MODE" >> "$LOG_FILE"
fi

exit 0
