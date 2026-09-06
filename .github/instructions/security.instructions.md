---
applyTo: "**/{payment,card,auth,pci}/**/*.java"
---

# PCI-DSS scoped code — security rules

These paths handle cardholder data, authentication, or payment flows and
are in PCI-DSS scope. These rules are additive on top of
`java.instructions.md` and `copilot-instructions.md` — they don't replace
them.

> This is essentials-level guidance for day-to-day coding suggestions, not
> a substitute for the full internal PCI-DSS policy. For the complete
> policy text and control mappings, see the reference doc bundled with the
> `pci-dss-reference` skill rather than pasting the full policy here.

## Cardholder data handling

- Never store full PAN, CVV/CVV2, or full track data at rest — CVV must
  never be stored post-authorization under any circumstance, even
  encrypted.
- Where a PAN must be referenced after initial processing, use the
  existing tokenization service — don't invent a new local encoding or
  truncation scheme.
- If PAN must appear in logs/UI for legitimate business reasons, mask it
  (show only first 6 / last 4 digits max) using the shared masking
  utility — don't hand-roll substring logic.
- Any new field that could hold cardholder or authentication data needs
  an explicit classification comment/annotation and encryption at rest —
  don't assume "it's just a test/staging table."

## Logging & telemetry

- Never log: PAN, CVV, full track data, passwords, auth tokens, session
  IDs, or full request/response bodies for endpoints in these packages.
- Prefer logging a stable non-reversible identifier (e.g. transaction ID,
  tokenized reference) over the sensitive value itself.
- Audit-relevant events (auth success/failure, payment authorization,
  card data access) must go through the existing audit logging facility,
  not ad hoc `log.info` calls — audit logs have different retention and
  access-control requirements than application logs.

## AuthN/AuthZ

- Don't weaken, bypass, or add a flag to skip an existing authentication
  or authorization check, even temporarily for testing — use the
  provided test fixtures/test users instead.
- New endpoints under these packages must have an explicit
  authorization check (method security annotation or equivalent) — never
  rely on "it's not linked from the UI" as the control.
- Session tokens, JWTs, and API keys are never logged, embedded in URLs,
  or stored in `localStorage`-equivalent client storage.

## Input validation & crypto

- Validate and sanitize all input at the boundary (controller/DTO
  validation annotations), not deep in the service layer as the only
  check.
- Use the platform-approved crypto libraries/config (TLS versions, cipher
  suites, key management) — don't introduce ad hoc crypto (custom
  hashing, home-rolled encryption, `MD5`/`SHA1` for anything security
  relevant).
- Parameterized queries / the ORM only — no string-concatenated SQL,
  even for "internal" queries in this package.

## Dependencies & scanning

- Flag (don't silently accept) a new dependency added under these
  packages so it goes through dependency/SCA scanning before merge.
- Never suppress a SAST/SCA/secret-scan finding on code in these paths
  without a documented justification and reviewer sign-off — see
  `copilot-instructions.md`.
