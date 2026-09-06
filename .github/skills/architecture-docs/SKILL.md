---
name: architecture-docs
description: >-
  Methodology for deriving and maintaining docs/architecture.md (a
  12-section system-level summary: overview, layered architecture,
  components, data flow, external systems, data architecture, security,
  deployment, reliability, observability, ADR index, detailed-design
  index) plus the detailed design docs (docs/design/) and ADRs
  (docs/decisions/) it links out to. Use when generating/refreshing
  docs/architecture.md, writing a detailed design or ADR, or checking
  whether an architecturally significant change updated any of these.
---

# Architecture documentation methodology

Everything under `docs/architecture.md`, `docs/design/`, and
`docs/decisions/` is a **derived-or-decided artifact**, not prose written
from vibes:

- Facts about the system (diagrams, config, timing, security mechanisms)
  must trace to something actually in the codebase. Never invent a
  value, a dependency, or a timing number that isn't backed by something
  you found. Where a section can't be verified, write "not found in code
  — needs confirmation" rather than guessing; a wrong SLA or DLQ claim is
  worse than an acknowledged gap, especially for a PCI-relevant service
  where downstream timeout budgets are a real operational input.
- Decisions recorded as ADRs must trace to an actual decision that was
  made (a `/plan` output, a PR discussion, a real tradeoff someone
  chose) — don't retroactively invent a rationale for something that
  just happened to be built a certain way.

## The three documents and how they relate

```
docs/architecture.md   — one page, system-level summary, links out
  ├─ §11 Architectural Decisions → docs/decisions/NNNN-*.md (ADRs)
  └─ §12 Detailed Designs        → docs/design/*.md (deep dives)
```

`docs/architecture.md` should stay readable in one sitting. When a
section would need to get long enough to threaten that, that's the
signal to summarize it there and move the depth to a linked document
instead of letting the summary bloat.

Use `references/architecture-template.md` for the 12-section skeleton,
`references/sla-calculation.md` for reliability (§9: SLA timing, DLQ,
idempotency), `references/detailed-design-template.md` for a new
`docs/design/*.md`, and `references/adr-template.md` for a new
`docs/decisions/NNNN-*.md` — don't reinvent any of these from scratch.

## Sourcing each architecture.md section

**§1 Overview** — what the service does and its boundaries. Pull from an
existing README/module-info if present; otherwise state it plainly from
what the code actually does, not aspirational language nobody verified.

**§2 Architecture / §3 Components** (Mermaid `flowchart`) — the layered
view (typically API → Application → Domain → Infrastructure, or whatever
this codebase's actual layering is). Derive layer boundaries and
responsibilities from actual package structure and Spring bean wiring —
an arrow means one layer actually calls/depends on the other in code, not
an assumed relationship. If the codebase's real layering doesn't match a
clean textbook shape, document what's actually there, not the idealized
version.

**§4 Data Flow** (Mermaid `sequenceDiagram`) — one per significant flow.
Trace an actual call path: controller → service → downstream calls →
response, including where a retry or fallback branches the flow. This is
the *summary* version — full detail for a complex flow belongs in its
own `docs/design/*.md` (see below), linked from here.

**§5 External Systems** — every external/internal system this app
depends on, plus the config properties that wire each one up (database,
Kafka/MQ brokers and topics/queues, outbound APIs). Source from
`application.yml`/`.properties` (all profiles), `@Value`/
`@ConfigurationProperties` classes, connection-factory/client bean
definitions, and Feign/`WebClient`/`RestTemplate` base URLs. Property
keys and what they configure, never real values — reference the secrets
manager instead of copying a secret (see non-negotiables in
`copilot-instructions.md`).

**§6 Data Architecture** (Mermaid `erDiagram` + ownership narrative) —
derive the diagram from actual `@Entity` classes / JPA mappings / DB
migrations, not DTOs. Ownership (which service/team owns which
tables/schemas) comes from actual access patterns in code if not stated
elsewhere — don't assert ownership you can't back up.

**§7 Security** — what's actually implemented (authN mechanism, authZ
model, secrets management, encryption, network security), derived from
Spring Security config, OAuth2/JWT config, deployment network policies.
This documents *what's implemented*; the rules that govern how it's
built live in `.github/instructions/security.instructions.md` — link to
that rather than duplicating it.

**§8 Deployment** — platform and topology derived from actual IaC
(Terraform, Helm values, OpenShift templates/DeploymentConfig) — resource
limits, replica/autoscaling config, environment topology only where a
real manifest backs the number.

**§9 Reliability** — see `references/sla-calculation.md` for the full
methodology (SLA timing math, DLQ, idempotency). Every number and every
DLQ/idempotency claim needs a cited config key or code location.

**§10 Observability** — logging aggregation, metrics export, tracing,
and alerts, derived from actual observability config/dependencies
(Micrometer/Prometheus, OpenTelemetry, log config). Don't describe an
alert that only exists in a dashboard UI you can't verify from code.

**§11 Architectural Decisions / §12 Detailed Designs** — index only, see
below for when to create the linked documents.

## When to create a detailed design doc or ADR

Not every change needs one — most don't. Create a `docs/design/*.md`
when a flow is complex enough that the §4 summary diagram would either
have to omit real branches/edge cases or become unreadable trying to
include them (multi-step sagas, complex state machines, anything with
non-obvious failure/retry/compensation logic). Create a
`docs/decisions/NNNN-*.md` ADR when a decision was genuinely contested —
there was a real alternative someone could have chosen instead, and the
reasoning for not choosing it is worth preserving. A straightforward
implementation of an already-settled pattern needs neither.

When creating a detailed design or ADR, add the corresponding link under
§12 or §11 of `docs/architecture.md` in the same pass — an orphaned
detailed-design doc nobody can find from the index is close to useless.

## Keeping it current vs. full regeneration

Two update modes, both valid depending on why you're being invoked:

- **Targeted update** — a specific change added/removed a dependency,
  changed a retry/timeout/circuit-breaker/DLQ/idempotency mechanism,
  changed a component boundary, or warranted a new detailed
  design/ADR. Update only the affected section(s) of
  `docs/architecture.md` (plus the new linked document); don't
  regenerate the whole summary and risk clobbering hand-written context
  that isn't re-derivable from code (like §1 prose).
- **Full regeneration/audit** — no existing `docs/architecture.md`, or
  it's suspected to have drifted significantly. Rebuild all sections
  from the current codebase, and if a prior version exists, flag
  material discrepancies (a documented dependency no longer in code, a
  changed SLA number, a dead link to a detailed design) rather than
  silently overwriting without explaining what changed.

In both modes, end with a short "Sources" note per major section (which
files you derived it from) so a human can spot-check without re-deriving
everything themselves.
