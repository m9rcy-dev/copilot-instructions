#!/usr/bin/env bash
# preToolUse hook: fail-closed secret scan before a git commit goes through.
#
# Copilot CLI passes hook context as JSON on stdin. We only care about
# shell/bash tool calls whose command looks like a `git commit`. For those,
# scan the staged diff for likely secrets and exit 2 (blocks the tool call)
# if anything matches. Any other tool call is a no-op pass-through.
#
# Requires: jq. Prefers `gitleaks` if installed on PATH; falls back to a
# small built-in regex set otherwise (best-effort, not a replacement for
# gitleaks/trufflehog in CI).

set -euo pipefail

input="$(cat)"

command_str="$(echo "$input" | jq -r '.tool_input.command // .command // empty' 2>/dev/null || true)"

if [[ -z "$command_str" ]]; then
  exit 0
fi

if ! echo "$command_str" | grep -Eq 'git[[:space:]]+commit'; then
  exit 0
fi

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
cd "$repo_root"

if command -v gitleaks >/dev/null 2>&1; then
  if ! gitleaks protect --staged --redact -v; then
    echo "BLOCKED: gitleaks found likely secrets in the staged diff. Fix or unstage before committing." >&2
    exit 2
  fi
  exit 0
fi

# Fallback: minimal built-in patterns if gitleaks isn't available.
# Not exhaustive — install gitleaks for real coverage.
diff_content="$(git diff --cached -U0 -- . ':(exclude)*.lock' ':(exclude)*package-lock.json' || true)"

patterns=(
  '-----BEGIN [A-Z ]*PRIVATE KEY-----'
  'AKIA[0-9A-Z]{16}'                       # AWS access key id
  'aws_secret_access_key\s*=\s*[A-Za-z0-9/+=]{20,}'
  '(api|secret|access)[_-]?key["\047]?\s*[:=]\s*["\047][A-Za-z0-9_\-]{16,}["\047]'
  'sk_live_[A-Za-z0-9]{16,}'               # live payment/API keys, e.g. Stripe
  'ghp_[A-Za-z0-9]{36}'                    # GitHub PAT
  'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'  # JWT-shaped
)

found=0
for pat in "${patterns[@]}"; do
  if echo "$diff_content" | grep -EIq "$pat"; then
    echo "BLOCKED: staged diff matches secret-like pattern: $pat" >&2
    found=1
  fi
done

if [[ "$found" -eq 1 ]]; then
  echo "Fix or unstage the offending lines before committing. (Fallback scanner — install gitleaks for stronger coverage.)" >&2
  exit 2
fi

exit 0
