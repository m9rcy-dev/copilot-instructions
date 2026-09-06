---
applyTo: "**/*.java"
---

# Java / Spring Boot conventions

## Structure & layering

- Standard layering: `controller` → `service` → `repository`. Controllers
  stay thin — request/response mapping and validation only, no business
  logic. Business logic lives in services; services don't know about
  HTTP (no `HttpServletRequest`, no status codes).
- Package by feature (`payment/`, `card/`, `auth/`), not by layer
  (`controllers/`, `services/`) at the top level.
- Use constructor injection everywhere. No field injection (`@Autowired`
  on a field), no setter injection.
- DTOs at the API boundary, entities at the persistence boundary — don't
  return `@Entity` objects directly from controllers.

## Style

- Prefer Java records for immutable DTOs/value objects. Use Lombok
  (`@Value`, `@Builder`) only where records don't fit (e.g. JPA entities
  needing mutability).
- Favor `Optional<T>` for return types that can legitimately be empty;
  never for fields or method parameters.
- No `null` returns from public methods where `Optional` or a documented
  sentinel would do — if `null` is unavoidable, say why in a one-line
  comment.
- Keep methods short enough to read on one screen. Extract, don't nest —
  prefer early returns over deep `if` nesting.

## Error handling

- Use a centralized `@ControllerAdvice` / `@ExceptionHandler` for
  translating exceptions to HTTP responses — don't catch-and-map
  exceptions ad hoc in individual controllers.
- Custom exceptions extend a common base per bounded context (e.g.
  `PaymentException`) so the advice can pattern-match by type.
- Never swallow an exception silently (empty `catch` block). Either
  handle it meaningfully, wrap and rethrow with context, or let it
  propagate.

## Documentation

- Every public class gets a class-level Javadoc: its responsibility and
  where it fits (e.g. "service coordinating X for Y"), not a restatement
  of the class name.
- Every public method gets a Javadoc: `@param`/`@return`/`@throws` as
  applicable, plus a sentence on **why** the method exists or why it does
  something non-obvious — the intent, not just the mechanics the
  signature already shows.
- Keep Javadoc and inline comments self-contained. Don't reference a
  ticket number, PR, design doc, or "as discussed" — that context won't
  necessarily ship with the code and a future reader can't resolve it.
  If a decision needs justifying, justify it inline in the comment
  itself.

## Testing

- Both unit and integration tests are required for a change to be
  considered complete — one without the other is a gap, not a tradeoff.
- Unit tests cover business logic in isolation: services with
  repositories/collaborators mocked (Mockito), covering the happy path
  and meaningful failure/edge cases.
- Integration tests exercise the real wiring — `@SpringBootTest` (full
  context) or targeted slices (`@WebMvcTest`, `@DataJpaTest`) for
  controller-to-persistence flows, actual serialization, validation, and
  exception-advice behavior end to end. Use the narrowest slice that
  still exercises the real integration point; don't reach for a full
  context load when a slice test covers it, but don't skip integration
  coverage entirely just because unit tests pass.
- Test names describe behavior: `shouldRejectExpiredCard()`, not
  `test1()`.
- Never use real card numbers, tokens, or customer data in test
  fixtures — use documented test-only values (e.g. the standard Luhn-valid
  test PANs), and never fetch fixtures from production data.

## Logging

- Use the SLF4J API (`LoggerFactory.getLogger`), never `System.out`.
- Log at the boundary where context is available (service layer), not
  deep in helpers, to avoid duplicate log lines for one event.
- Structured/parameterized logging (`log.info("Payment {} declined", id)`),
  never string concatenation — and never log full request/response bodies
  for endpoints under `payment/`, `card/`, or `auth/` (see
  `security.instructions.md`).

## Dependencies

- Don't add a new dependency for something the JDK or an already-present
  library covers.
- Check for an existing internal shared library before adding a new
  third-party one for common concerns (HTTP client, retry, JSON mapping).
