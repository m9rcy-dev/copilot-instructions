---
description: Final holistic review before opening a PR — instructions compliance, best practices, and missed-integration check across the codebase.
agent: pre-pr-review
---

Run a pre-PR review of ${input:target:the current uncommitted diff}.

Check rule-by-rule compliance with
`.github/instructions/java.instructions.md` (and
`.github/instructions/security.instructions.md` if applicable), compare
against the closest existing analog in the codebase for consistency, and
search for missed integration points — related places a change like this
usually also touches that don't appear in the diff.

Assume `/validate` and `/security-review` have run or will run separately
— don't duplicate their checks, just note briefly if you spot something
squarely in their scope.

Report file:line findings with severity (blocking/advisory) and end with
a PASS/BLOCKED verdict. Do not edit any files — this is a report only.
