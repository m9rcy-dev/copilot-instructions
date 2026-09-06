#!/usr/bin/env bash
# setup-project.sh
#
# Run this inside the target project repo (the real Java/Spring Boot repo
# you're adding this Copilot scaffold to), after copying .github/ and
# docs/progress.md into it.
#
# It ensures `.github/` (EXCEPT `.github/workflows/`) and
# `docs/progress.md` are excluded from that repo's commits:
#   1. Updates .gitignore (creates it if missing, safe to re-run).
#   2. Untracks any of those paths that were already `git add`ed or
#      committed (`git rm --cached`) WITHOUT touching files on disk.
#   3. Explicitly keeps/stages `.github/workflows/` as TRACKED.
#
# Why workflows/ is a carve-out: GitHub Actions only runs workflow files
# that are actually committed on the branch/PR being built — a CI
# workflow gitignored like the rest of .github/ would simply never run.
# Everything else in .github/ (instructions, prompts, agents, skills,
# hooks) still works for YOU locally even if untracked, since Copilot
# clients read those straight off disk — but workflows/ has no local-only
# mode, so it's excluded from the ignore rule.
#
# Gitignore mechanics note: a bare `/.github/` pattern excludes the whole
# directory, and git cannot re-include (`!pattern`) anything nested
# inside an already-excluded parent directory — that's a hard git
# limitation, not something a smarter pattern can work around. So this
# script excludes `.github/`'s *contents* one level at a time
# (`/.github/*`) instead of the directory itself, which is what makes the
# `!/.github/workflows/` negation actually take effect.
#
# This script never runs `git commit` or `git push` — it only stages
# changes. Review with `git status` / `git diff --cached` and commit
# yourself when ready.
#
# Usage:
#   ./scripts/setup-project.sh

set -euo pipefail

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "Error: not inside a git repository. cd into your project (or run" >&2
  echo "'git init' yourself first — this script won't do that for you) " >&2
  echo "and re-run." >&2
  exit 1
}
cd "$repo_root"

gitignore_file="$repo_root/.gitignore"
touch "$gitignore_file"

add_ignore_entry() {
  local pattern="$1"
  if grep -qxF "$pattern" "$gitignore_file"; then
    echo "  already in .gitignore: $pattern"
  else
    printf '%s\n' "$pattern" >> "$gitignore_file"
    echo "  added to .gitignore: $pattern"
  fi
}

echo "Updating .gitignore..."
# Migrate an older/broader "/.github/" entry if present — see the
# gitignore mechanics note above for why that form can't carve out
# .github/workflows/.
if grep -qxF "/.github/" "$gitignore_file" 2>/dev/null; then
  migrate_tmp="$(mktemp)"
  grep -vxF "/.github/" "$gitignore_file" > "$migrate_tmp" || true
  mv "$migrate_tmp" "$gitignore_file"
  echo "  migrated: removed blanket '/.github/' entry (replacing with a form that allows workflows/ to stay tracked)"
fi
add_ignore_entry "/.github/*"
add_ignore_entry "!/.github/workflows/"
add_ignore_entry "/docs/progress.md"

untrack_if_tracked() {
  local path="$1"
  if [[ ! -e "$path" ]]; then
    return 0
  fi
  if git ls-files --error-unmatch -- "$path" >/dev/null 2>&1; then
    echo "  untracking (was previously tracked/committed): $path"
    git rm -r --cached --quiet -- "$path"
    echo "    -> staged for removal from git's index. Files on disk are"
    echo "       untouched. If this path was committed before, it still"
    echo "       exists in git history — this only stops FUTURE commits"
    echo "       from including it."
  else
    echo "  not tracked (nothing to do): $path"
  fi
}

echo ""
echo "Checking for already-tracked paths..."
if [[ -d ".github" ]]; then
  for entry in .github/*; do
    [[ -e "$entry" ]] || continue
    if [[ "$(basename "$entry")" == "workflows" ]]; then
      continue
    fi
    untrack_if_tracked "$entry"
  done
fi
untrack_if_tracked "docs/progress.md"

echo ""
echo "Ensuring .github/workflows/ stays tracked (required for CI to run)..."
if [[ -d ".github/workflows" ]]; then
  git add .github/workflows
  echo "  staged: .github/workflows"
else
  echo "  no .github/workflows/ present — nothing to stage."
fi

echo ""
echo "Done. Nothing was committed or pushed."
if ! git diff --cached --quiet 2>/dev/null; then
  echo "There are staged changes above — review with:"
  echo "  git status"
  echo "  git diff --cached --stat"
  echo "and commit yourself when ready."
fi
