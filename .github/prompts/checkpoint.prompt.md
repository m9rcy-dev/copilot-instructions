---
description: Check whether this session has gotten heavy enough to checkpoint; if so, write a RESUME_POINT and recommend starting a fresh chat.
agent: java-pair
---

Apply the `context-hygiene` skill to this session: assess the proxy
signals (session length, accumulated tool output, self-observed drift,
whether a task boundary has been reached), and say plainly whether this
looks like a good time to checkpoint. Don't claim an exact context-usage
number — you don't have one; explain your call in terms of the actual
signals you're seeing.

If yes: use the `session-recovery` skill to write a `RESUME_POINT` to
`docs/progress.md` capturing exactly what's done, in progress, and not
started — verified against actual repo state, not assumed. Then tell me
to start a new chat and run `/session-resume`.

If no: say briefly why not, and continue with the current task.
