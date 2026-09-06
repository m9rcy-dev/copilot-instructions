#!/usr/bin/env bash
# preToolUse hook: fail-closed build+test gate before a git commit goes
# through. Runs alongside scan-secrets-pretooluse.sh (both are separate
# preToolUse entries in hooks.json — a commit is blocked if either fails).
#
# This runs the project's actual build/test command, not a guess — a
# green "tests added" claim from a model is not the same as tests that
# actually pass. Detects Maven vs Gradle by the presence of pom.xml /
# build.gradle(.kts). If neither is found, this is not a Java project
# this hook recognizes — it passes through with a warning rather than
# blocking, since we can't assume the build layout.
#
# NOTE: this runs the full build+test suite on every commit, which can be
# slow. That's a deliberate tradeoff for a fail-closed gate; if it's too
# slow in practice, scope it down (e.g. only affected modules) rather
# than disabling it outright. CI remains the final authority regardless —
# this is a local backstop so failures are caught before they leave your
# machine, not a replacement for CI.

set -uo pipefail

input="$(cat)"
command_str="$(echo "$input" | jq -r '.tool_input.command // .command // empty' 2>/dev/null || true)"

if [[ -z "$command_str" ]]; then
  exit 0
fi

if ! echo "$command_str" | grep -Eq 'git[[:space:]]+commit'; then
  exit 0
fi

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
cd "$repo_root" || exit 0

run_build() {
  if [[ -f "pom.xml" ]]; then
    echo "Detected Maven project — running: mvn -q verify"
    mvn -q verify
    return $?
  fi

  if [[ -f "build.gradle" || -f "build.gradle.kts" ]]; then
    local gradle_cmd="gradle"
    if [[ -x "./gradlew" ]]; then
      gradle_cmd="./gradlew"
    fi
    echo "Detected Gradle project — running: $gradle_cmd check"
    "$gradle_cmd" check
    return $?
  fi

  echo "No pom.xml or build.gradle(.kts) found at repo root — skipping" \
       "build/test gate (not blocking, can't determine build tool)." >&2
  return 0
}

if ! run_build; then
  echo "BLOCKED: build/test failed. Fix the failing build or tests before committing." >&2
  echo "(To verify locally without committing, run the same command directly, or use /validate.)" >&2
  exit 2
fi

exit 0
