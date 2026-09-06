# Detailed design: <flow/component name>

_Linked from [Architecture](../architecture.md) §12. Last updated:
<date>._

## Scope

What this document covers, and — as importantly — what it deliberately
doesn't (link to a sibling detailed design instead of duplicating).

## Context

Why this exists / what problem it solves. One or two paragraphs, not a
restatement of the architecture overview — assume the reader already
read `docs/architecture.md`.

## Design

The actual mechanics, in as much depth as this flow warrants:

```mermaid
sequenceDiagram
  %% full detail — every branch, every retry, every error path.
  %% architecture.md §4 has the summary version; this is the real one.
```

Cover, as relevant to this specific flow: request/message shape, state
transitions, ordering guarantees, concurrency handling, failure modes
and how each is actually handled (not just named), edge cases that
required a deliberate decision.

## Data

Tables/entities/topics this flow specifically touches, beyond what's
already in `docs/architecture.md` §6 — schema details, message schema,
retention, partitioning, if relevant.

## Reliability specifics

Anything about this flow's retry/idempotency/DLQ behavior more specific
than the summary in `docs/architecture.md` §9 — e.g. exactly what makes
this operation idempotent, what happens to a message that exhausts
retries.

## Open questions / known limitations

Things that are genuinely unresolved or accepted tradeoffs — don't hide
these to make the design look more finished than it is.

## Sources

Files this was derived from / implements.
