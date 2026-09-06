---
description: Run a PCI-DSS-focused security review of the current diff or a specified path.
agent: security-reviewer
---

Review ${input:target:the current uncommitted diff} for PCI-DSS and
security issues per `.github/instructions/security.instructions.md` and
the non-negotiables in `.github/copilot-instructions.md`.

Report findings as: file:line, what's wrong, why it matters, concrete
fix, and severity (blocking vs. advisory). If you find nothing, say so
explicitly. Do not edit any files — this is a report only.
