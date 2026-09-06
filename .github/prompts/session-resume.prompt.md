---
description: Check docs/progress.md for an in-progress task and resume it, verifying claimed state before trusting it.
agent: java-pair
---

Use the `session-recovery` skill: read `docs/progress.md` for the latest
`RESUME_POINT` entry. Verify its claimed state against actual repo state
(don't trust the log blindly — check files/tests/migrations mentioned
actually match reality) before resuming. Summarize what you found and
what you're about to do next, then continue the task from there.

If no `RESUME_POINT` is present, say so and ask what to work on.
