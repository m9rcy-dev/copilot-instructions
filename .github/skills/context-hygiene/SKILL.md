---
name: context-hygiene
description: >-
  Heuristics for noticing when a session's context has gotten heavy
  enough that response quality is likely degrading ("context rot"), and
  the checkpoint-and-restart protocol to use instead of pushing further
  into an already-long session. Reuses the `session-recovery` skill's
  docs/progress.md RESUME_POINT mechanism as the handoff format. Use
  periodically during any long-running task, at natural task
  boundaries, and whenever `/checkpoint` is invoked.
---

# Context hygiene

**Important limitation, stated up front:** you do not have access to an
exact token count or context-window-usage percentage — no tool here
reports that number. Anything that claims a precise usage figure is
guessing. Use the proxy signals below instead of pretending to a
precision you don't have.

## Why this exists

Model quality on a long context degrades before the hard context limit
is hit — recall of early instructions weakens, accumulated tool output
crowds out the actual task, and it becomes easier to contradict a
decision made earlier in the same session without noticing. The fix
isn't pushing further and hoping — it's checkpointing task state and
starting a fresh session *before* quality visibly degrades, not after.

## Proxy signals to actually watch

Treat any of these as a reason to check in with the operator about
checkpointing — not as a reason to silently keep going:

- **Long session** — many substantive back-and-forth turns on one
  continuous task (rough rule of thumb: past ~25-30 exchanges without a
  break).
- **Heavy accumulated tool output** — several full reads of large
  files, long build/test logs, large diffs, or verbose search results
  piled up over the course of the conversation.
- **Self-observed drift** — you notice yourself re-reading a file you
  already read this session because you'd lost track of its contents,
  re-deriving a decision already made earlier in this same
  conversation, or about to contradict a constraint stated earlier in
  this session. This is the most reliable signal you actually have,
  since it's a direct observation rather than a proxy.
- **Task-boundary reached** — a plan step just finished, or a subtask
  is fully done. Worth checkpointing here even without either signal
  above firing, since it's cheap and the next chunk of work starts
  clean on a natural seam instead of mid-step.

## What to do when a signal fires

1. Say so, plainly — e.g. "this session's gotten long and I'm noticing
   rough edges (re-reading X, this is exchange #N on one task);
   recommend checkpointing and starting fresh." Don't silently push
   through, and don't unilaterally end the session — only the operator
   can actually open a new chat window.
2. Use the `session-recovery` skill to write a `RESUME_POINT` to
   `docs/progress.md`: what's done, what's in progress, what's not
   started, and any gotchas — written so a fresh session with zero
   memory of this one can pick up correctly. Verify claimed state
   before writing it down (same rule as `session-recovery`), don't
   just assert it from memory.
3. Tell the operator explicitly: start a new chat and run
   `/session-resume` (or invoke the `session-recovery` skill directly)
   to continue. You cannot clear your own context — that part is a
   client/operator action, not something an agent can trigger.

## What NOT to do

- Don't checkpoint every few messages "just in case" — that's noise,
  and the whole point of `docs/progress.md` is that only real resume
  points live there (see `session-recovery`'s "not a general changelog"
  rule).
- Don't claim a precise context-usage percentage or token count — you
  don't have that number. Speak in terms of the actual proxy signals
  above, not a fabricated metric.
- Don't checkpoint mid-step in a way that leaves inconsistent or
  half-applied code as the "done" state — finish (or cleanly roll back)
  the current atomic step first wherever possible, then checkpoint at
  the seam.
