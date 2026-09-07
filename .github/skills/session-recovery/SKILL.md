---
name: session-recovery
description: >-
  Read or write docs/progress.md crash-recovery state using RESUME_POINT
  markers. Use at the start of any session on a multi-step task to check
  for in-progress work before starting fresh, and periodically during long
  or multi-session work to checkpoint progress so a crashed/context-reset
  session can resume without re-deriving what's already been done. Also
  covers archiving docs/progress.md to a dated file once completed-task
  history piles up, so the active file stays small.
---

# Session recovery via docs/progress.md

`docs/progress.md` is this repo's crash-recovery log for multi-step or
multi-session work (a large refactor, a migration, a feature spanning
several sessions). It is NOT a general changelog — don't write to it for
small, single-session tasks.

## On session start (for any non-trivial task)

1. Check whether `docs/progress.md` exists and has a `RESUME_POINT` entry
   newer than the last completed item.
2. If a `RESUME_POINT` is found:
   - Read the full entry: what task, what was done, what's left, why it
     stopped (crash, context limit, deliberate pause).
   - Verify the claimed state against reality before trusting it — e.g.
     if it says "migration applied", check the migration actually ran;
     if it says "tests passing", don't assume, re-run them. Code/repo
     state is the source of truth; the log is a pointer to where to look,
     not a substitute for checking.
   - Resume from there instead of restarting the task.
3. If no relevant `RESUME_POINT` exists, proceed normally — no need to
   create one for short tasks.

## During long-running work

Append a checkpoint before any risky/interruptible step (large refactor
touching many files, long-running migration, anything that might exceed
context or get interrupted):

```markdown
## RESUME_POINT — 2026-09-06T14:30Z

**Task:** Migrate card-token storage to new vault-backed tokenization
service.

**Done:**
- Vault client wired into `TokenService`.
- Read path migrated and tested (`TokenServiceTest`).

**In progress / next:**
- Write path migration — `TokenService.store()` still writes old format.
  Next step: update `store()`, then run the backfill script for existing
  rows (see `scripts/backfill-tokens.sh`, not yet run).

**Not started:**
- Remove old `LegacyTokenRepository` once backfill confirmed complete.

**Notes:** Backfill script is idempotent, safe to re-run. Don't drop the
old column until backfill is verified in staging.
```

Keep entries factual and specific enough that a different session (no
memory of this one) could pick up correctly — file paths, what was
verified vs. assumed, and any gotchas.

## On task completion

Collapse the `RESUME_POINT` entry into a brief, dated one-line "done"
summary (e.g. `- 2026-09-06: Migrated card-token storage to vault-backed
tokenization.`) in place of the full entry, so stale in-progress detail
doesn't accumulate and mislead future sessions. Newest at the top, same
as `RESUME_POINT`s.

## Archiving (prevent unbounded growth)

`docs/progress.md` is meant to hold only the *current* window of work,
not a running history — even one-line completed summaries pile up
indefinitely otherwise, and a long file is exactly the kind of
accumulated context the `context-hygiene` skill warns against reading
in full every session.

After collapsing a completed task into a one-line summary (above), count
how many completed one-line summaries are now sitting in
`docs/progress.md`. Once that count reaches **2** (i.e. two full plans'
worth of completed history accumulated — adjust this threshold if the
operator asks for a different cadence), archive instead of leaving a
third:

1. Copy the *current full contents* of `docs/progress.md` (including the
   summary you just added) to `docs/progress.md.<UTC timestamp>`, using
   `YYYY-MM-DDTHH-MM-SSZ` format with colons replaced by `-` so it's a
   valid filename — e.g. `docs/progress.md.2026-09-07T14-30-00Z`. This
   preserves the history rather than discarding it.
2. Overwrite `docs/progress.md` back to the empty template
   (`_No active work in progress._`, no completed summaries carried
   forward) — a clean slate, not a reference to the archive file.
3. Mention the archive filename in your summary to the operator, so they
   know where the prior history went if they need to look something up
   later.

Only archive at this point — right after a task completes and the file
would otherwise cross the threshold. Never archive out from under an
active `RESUME_POINT`; a session mid-task always wins over pruning.
