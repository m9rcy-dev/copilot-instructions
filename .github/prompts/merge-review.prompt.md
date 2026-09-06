---
description: Arms-length review of a branch/PR merging to main/master — checks intent match (does the diff do what it claims) and full guideline compliance.
agent: merge-review
---

Review ${input:target:the current branch} for merge into
main/master.

Get the full diff against main/master (not just the latest commit), plus
the PR title/description and commit messages if available. Check whether
the diff actually does what's claimed (intent match), whether the
complete diff complies with
`.github/instructions/java.instructions.md` and, if applicable,
`.github/instructions/security.instructions.md`, and any merge-specific
risk (breaking changes, cross-PR dependencies, immediate-effect config).

Report findings with severity (blocking/advisory) and end with a
PASS/BLOCKED verdict. Do not edit any files — this is a report only.
