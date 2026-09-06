---
description: Propose a specific instructions-file addition that would have caught a bug that escaped review or reached production.
agent: planner
---

A bug escaped review/production: ${input:incident}.

Identify the root cause and whether an existing instructions file
(`.github/instructions/java.instructions.md` or
`.github/instructions/security.instructions.md`) should have had a rule
that would have caught this class of bug — not just this specific
instance. If so, propose the exact addition: which file, where it fits
among the existing sections, and the precise wording (matching the
existing style — short, concrete, a why when it's non-obvious).

If the real gap isn't a missing instruction (e.g. it's a one-off mistake,
or something `quality-gate`/`pre-pr-review` already would have caught if
run), say that instead of forcing a speculative rule into the file —
don't pad the instructions with something that wouldn't generalize.

This is a proposal for a human to review and apply — do not edit any
files yourself.
