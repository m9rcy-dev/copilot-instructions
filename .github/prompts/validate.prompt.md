---
description: Check the current diff (or a given path) against the Definition of Done checklist — build, tests, docs, Clean Code/SOLID, scope.
agent: quality-gate
---

Validate ${input:target:the current uncommitted diff} against the
Definition of Done checklist in `.github/copilot-instructions.md`. Run
the actual build/test commands to verify claims rather than assuming.
Report status per checklist item with evidence, flag blocking vs.
advisory issues, and end with a PASS/BLOCKED verdict.

If this touches `payment/`, `card/`, `auth/`, or `pci/`, say so and note
that `/security-review` is still required in addition to this.

Do not edit any files — this is a report only.
