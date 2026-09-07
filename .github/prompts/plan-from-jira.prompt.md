---
description: Read a Jira ticket, brainstorm gaps against the codebase, ask clarifying questions, then produce a written plan.
agent: jira-planner
---

Produce an implementation plan from this Jira ticket: ${input:ticket}.

Follow the `jira-planner` agent's phases: read the ticket in full,
brainstorm where it's ambiguous or silent relative to the actual
codebase, ask the operator targeted clarifying questions and wait for
answers, then write the plan in the standard planner format (goal,
approach, implementation steps, PCI/regulated-data scope, test plan,
risks, documentation impact).

Do not skip the clarification phase to save time, and do not write or
edit any code — this is a plan for review only.
