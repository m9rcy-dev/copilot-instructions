---
description: Scaffold a new REST endpoint (controller + service + DTOs + tests) following this repo's Java conventions.
agent: java-pair
---

Scaffold a new Spring Boot REST endpoint for: ${input:description}.

Follow `.github/instructions/java.instructions.md`:
- Thin controller (mapping/validation only), logic in a service.
- Request/response DTOs (records) separate from any entity.
- Constructor injection.
- Centralized exception handling via existing `@ControllerAdvice` — add a
  new exception type only if none of the existing ones fit.

Include:
- The controller method with validation annotations on the request DTO.
- The service method with a unit test (Mockito) covering the happy path
  and at least one failure/validation case.
- If this endpoint lives under `payment/`, `card/`, `auth/`, or `pci/`,
  also follow `.github/instructions/security.instructions.md` — call out
  in your response which specific rules applied (auth check, masking,
  audit logging) so it's easy to verify.

If anything about the request is ambiguous (which package it belongs in,
what auth is required, what the response shape should be), ask before
generating rather than guessing.
