---
description: Produce a written implementation plan for a request before any code is touched.
agent: planner
---

Produce an implementation plan for: ${input:request}.

Research the actual codebase before writing the plan — cite real file
paths and existing patterns, don't guess. Follow the planner agent's
format (goal, approach, files to touch, PCI/regulated-data scope, test
plan, risks/open questions). If the request is ambiguous in a way that
would change the approach, ask before producing the plan rather than
guessing.

Do not write or edit any code — this is a plan for review only.
