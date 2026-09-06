# Reliability methodology (SLA timing, DLQ, idempotency)

Backs `docs/architecture.md` §9 (Reliability). Compute timing from
**actually configured** values only — cite the config key and file for
every number used. If a value isn't configured explicitly, state the
library/framework default only if you can name it and its source;
otherwise mark it "not found — needs confirmation." The same rule
applies to the DLQ and idempotency sections below: describe what the
code actually does, not what would be reasonable to expect.

## Per-dependency worst-case latency

For a single dependency call protected by retry:

```
worst_case = (attempts × per_attempt_timeout) + sum(backoff between attempts)
```

Where `attempts` is the total number of tries **including the first**
(check the library's convention — Resilience4j's `max-attempts` and
Spring Retry's `maxAttempts` both include the initial attempt; don't
double-count or drop it).

- **Fixed backoff** (constant wait `w` between attempts):
  `sum(backoff) = (attempts - 1) × w`
- **Exponential backoff** (initial wait `w0`, multiplier `m`, optional
  cap `w_max`):
  `sum(backoff) = Σ min(w0 × m^i, w_max)` for `i` from `0` to
  `attempts - 2`
- Add jitter's configured max as a worst-case addend per gap if the
  config specifies one; otherwise note jitter is present but not
  included in the worst-case number (it only ever reduces contention,
  not the ceiling, unless configured as a multiplicative widening).

## Circuit breakers

A circuit breaker bounds *how many* worst-case sequences you can hit
before it opens and starts failing fast — it doesn't change the
per-attempt math above. Report both:

- The worst case *before* the breaker trips (using the retry math
  above, for calls made while the breaker is closed/half-open).
- That once open, calls fail fast (near-zero latency) until the
  configured wait-duration-in-open-state elapses — worth noting
  separately since it changes the failure mode from "slow" to "fast but
  erroring."

## Typical/expected-case latency

Report this alongside the worst case, not instead of it — a caller
setting their own timeout needs the worst case, but "typical" is what
actually matters for day-to-day SLA conversations:

- If observed latency metrics exist in the codebase/docs (e.g. a
  documented p95/p99), cite that.
- Otherwise, typical case ≈ a single successful attempt at the
  configured timeout is the *ceiling* for typical case, not the
  estimate itself — don't present the timeout value as if it were the
  expected latency; say plainly that actual typical latency isn't
  derivable from config alone and would need real metrics.

## End-to-end request SLA

For a request path touching multiple dependencies:

- **Sequential calls**: sum each dependency's worst case.
- **Parallel calls** (e.g. `CompletableFuture`/reactive fan-out joined
  before responding): take the max across the parallel branches, not the
  sum.
- Add the app's own processing/serialization overhead only if you have a
  real basis for a number (a documented budget, existing metric) —
  otherwise state that the total is dependency-timing-only and app
  overhead isn't included.

State the resulting number as what it is: a theoretical worst case
useful for setting the caller's own timeout/circuit-breaker budget, not
a promise of actual observed latency.

## Dead-letter queues

For each Kafka/MQ consumer, determine and report:

- **Does a DLQ actually exist for this consumer?** Look for DLQ topic/
  queue configuration, error-handler DLQ publishers (e.g. Spring Kafka's
  `DeadLetterPublishingRecoverer`), or MQ dead-letter routing config.
  Don't assume one exists because it would be good practice — if you
  can't find it, say DLQ handling isn't configured.
- **What routes a message there** — after how many retry attempts, on
  which exception types (all failures, or only non-retryable ones).
- **What happens after** — is there a reprocessing mechanism (a job, a
  manual runbook, nothing)? If you can't find one in code, say so rather
  than assuming messages get reprocessed.

## Idempotency

For each operation that can be retried (by this service's own retry
config, or by an upstream caller/message redelivery), determine whether
it's actually idempotent and how:

- **Idempotency key** — a client-supplied or generated key checked
  before applying an effect (look for a dedup table, a unique constraint
  used for this purpose, a cache-based check).
- **Natural idempotency** — an upsert / `INSERT ... ON CONFLICT` /
  set-based operation that's safe to repeat by construction.
- **Not idempotent** — if neither applies, say so explicitly. A retry
  config on a non-idempotent operation is a real reliability gap worth
  surfacing, not something to paper over by assuming it's fine.

Cite the specific code (a dedup check, a unique constraint, an upsert
statement) — "this looks like it should be idempotent" is not a finding,
it's a guess.
