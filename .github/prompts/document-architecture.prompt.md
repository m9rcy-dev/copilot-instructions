---
description: Generate/refresh docs/architecture.md, or write a linked detailed design / ADR — all derived from the actual codebase and actual decisions.
agent: architecture-doc
---

${input:scope:Do a full regeneration/audit of docs/architecture.md against the current codebase.}

Follow the `architecture-docs` skill's methodology. Every fact must trace
to something actually found in the code — no invented dependencies,
components, timing, or DLQ/idempotency claims; mark anything
unverifiable as such rather than guessing. Every ADR must trace to a
decision that was actually made, not an invented rationale.

If `docs/architecture.md` already exists, decide whether this is a
targeted update (only the sections a specific change affects), a full
regeneration, or a new detailed design/ADR (only if the skill's
threshold for one is actually met) — and say which you did. If you
create a detailed design or ADR, link it from `docs/architecture.md`
§12/§11 in the same pass. Only edit `docs/architecture.md`,
`docs/design/*.md`, and `docs/decisions/*.md` — never source code or
config.
