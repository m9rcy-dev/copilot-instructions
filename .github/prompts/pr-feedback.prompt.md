---
description: Address PR review comments and re-validate before the next push.
agent: pr-feedback
---

Address the following PR review feedback: ${input:comments}.

For each comment, make the minimal change that addresses it — ask if a
comment is ambiguous rather than guessing. Run the affected tests and fix
until green (same self-correction loop as `java-pair`). Once everything
in this batch is addressed, re-run `/validate` (and `/security-review` if
applicable) against the updated diff.

Summarize what changed per comment so a human can post it back to each
review thread. Do not push anything — that's a separate, explicit step.
