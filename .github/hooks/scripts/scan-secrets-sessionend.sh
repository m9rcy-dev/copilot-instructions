#!/usr/bin/env bash
# sessionEnd hook: best-effort audit scan, non-blocking (session is already
# over, nothing left to fail-closed against). Appends findings to a local
# audit log so a human can review. This is a backstop, not the gate — the
# real gate is scan-secrets-pretooluse.sh on `git commit`.

set -uo pipefail

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
cd "$repo_root" || exit 0

log_dir="$repo_root/.github/hooks/.audit-log"
mkdir -p "$log_dir"
log_file="$log_dir/secret-scan-$(date +%Y%m%d).log"

{
  echo "=== session end scan: $(date -u +%FT%TZ) ==="
  if command -v gitleaks >/dev/null 2>&1; then
    gitleaks detect --no-git -v --source . 2>&1 || echo "gitleaks: findings above (or scan error) — review manually"
  else
    echo "gitleaks not installed — skipping deep scan. Install gitleaks for session-end audit coverage."
  fi
} >> "$log_file" 2>&1

exit 0
