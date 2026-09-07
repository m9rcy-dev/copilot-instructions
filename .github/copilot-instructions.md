# Copilot Instructions — Java Backend

This file is always injected into every Copilot chat/completion request in this
repo, in every client (VS Code, IntelliJ, CLI, cloud agent). Keep it short —
it's the one file guaranteed to load everywhere. Deeper, path-scoped or
on-demand material lives in `.github/instructions/`, `.github/skills/`,
`.github/prompts/`, and `.github/agents/` — support for those varies by
client (see "Client support notes" below and the fuller matrix in
`README.md`) and shifts as this is an actively evolving preview surface,
so anything safety-critical belongs here, not there.

## What this service is

A Java / Spring Boot backend. Some codebases (or specific packages within
one) handle payment, cardholder, or other regulated data and fall under
PCI-DSS or similar compliance scope — treat any `payment/`, `card/`,
`auth/`, or `pci/` package as in that scope by default unless told
otherwise.

## Non-negotiables (apply everywhere, no exceptions)

**Security**
- **Never** print, log, hardcode, or echo real secrets, API keys, tokens,
  card numbers (PAN), CVV, or full account numbers — in code, commit
  messages, comments, test fixtures, or chat output. Use obviously-fake
  placeholders (`4111 1111 1111 1111` test PAN, `sk_test_xxx`, etc.) or
  reference a secrets manager.
- **Never** commit real credentials, `.env` files with live values, or
  private keys. If you find one already committed, stop and flag it —
  don't just add it to `.gitignore` going forward, the history still has it.
- **Never** weaken an existing security control (auth check, input
  validation, encryption, TLS config) to make a test or feature pass.
  Fix the root cause or ask.
- Prefer fixing the underlying issue over suppressing a linter, SAST, or
  dependency-scan finding. If a suppression is genuinely correct, it needs
  a comment explaining why and, for anything in a regulated-data scope, a
  human reviewer's sign-off — don't self-approve.

**Code quality**
- Follow Clean Code principles: intention-revealing names, small
  functions that do one thing, no dead code, no magic numbers/strings
  (named constants instead), minimal nesting, DRY without over-abstracting.
- Follow SOLID: single responsibility per class, open/closed via
  interfaces/composition rather than editing stable code to bolt on
  variants, Liskov-safe subtypes, narrow role-specific interfaces over
  fat ones, depend on abstractions (constructor-injected interfaces) not
  concrete implementations.

**Documentation**
- Every public class and public method gets a Javadoc comment. Class-level
  Javadoc states the class's responsibility and role in the system;
  method-level Javadoc states what it does, its parameters/return/thrown
  exceptions, and — most importantly — the **intent**: why this method
  exists and why it does it this way, when that isn't obvious from the
  signature alone.
- Comments and Javadoc must be self-contained: never reference a design
  doc, ticket, PR, Slack thread, plan, or "as discussed" context that
  isn't part of the codebase. A future reader only has the code in front
  of them — anything they need to understand it must live in the code
  itself, not in an external artifact that may never ship with it or may
  go stale/disappear.

**Testing**
- Every change ships with tests. Unit tests for business logic in
  isolation (mocked collaborators), and — just as important, don't treat
  it as optional — integration tests that exercise the real wiring
  (Spring context, persistence, HTTP layer) for anything touching a
  controller, repository, or cross-component flow.
- A feature isn't done until both the unit-level behavior and the
  end-to-end integration path are covered, not just one or the other.

## Git & workflow constraints (apply everywhere, no exceptions)

- **Never run `git commit`** unless the user's current request explicitly
  asks for a commit. Staging changes and showing a diff for review is
  fine; committing is not the default end state of a task.
- **Never run `git push`**, and especially never `git push --force` /
  `--force-with-lease`, unless explicitly instructed — and never push to
  `main`/`master`/a protected branch without explicit confirmation each
  time, even if a push was approved earlier in the session.
- **Never run destructive git commands** — `reset --hard`, `checkout --`
  / `restore` over uncommitted work, `clean -fd`, `branch -D`, rewriting
  shared history — unless explicitly requested. Run `git status` first
  and stash or ask before anything that could discard work. This is also
  a hard gate, not just an instruction: `guard-tool.sh` (Tool Guardian,
  `.github/hooks/`) blocks these at the shell level regardless of intent
  — see "Definition of done" below.
- **Never skip hooks or bypass checks** (`--no-verify`, disabling a
  pre-commit hook, bypassing signing) to force a commit or push through.
  If a hook fails, fix the underlying issue.
- **Never merge, close, self-approve, or self-merge a pull request.**
  Open/update a PR only when asked.
- Don't modify files outside the scope of the current request "while
  you're in there" — flag unrelated issues instead of fixing them
  silently in the same change.
- Ask before adding, removing, or upgrading a dependency; before
  changing CI/CD config, build scripts, or infra-as-code; and before any
  action whose effect reaches beyond this local working copy.
- A prior approval for one of these actions applies to that action only
  — it is not standing permission to repeat it later in the session
  without asking again.

## Definition of done

A change is not done just because it compiles. Before treating a task as
complete — yours or when reviewing someone else's — check all of these:

- [ ] Builds cleanly, no new warnings from anything already configured to
      warn.
- [ ] Unit tests added/updated and passing for the behavior changed.
- [ ] Integration tests added/updated and passing for anything touching a
      controller, repository, or cross-component flow — not optional,
      see the Testing non-negotiable above.
- [ ] Every new/changed public class and method has Javadoc capturing
      intent, self-contained (no references to tickets/docs/plans outside
      the code).
- [ ] No secrets, PAN, CVV, or credentials introduced anywhere (code,
      tests, comments, commit message).
- [ ] Follows the Clean Code / SOLID non-negotiables above — no
      unrelated refactors bundled in, no scope creep beyond the request.
- [ ] If the change touches `payment/`, `card/`, `auth/`, or `pci/`:
      satisfies `.github/instructions/security.instructions.md` and has
      had a pass from the `security-reviewer` agent / `/security-review`
      prompt.
- [ ] No existing security control, test, or check was weakened, skipped,
      or suppressed to get here.
- [ ] If this change is architecturally significant (new/removed service
      dependency, changed retry/timeout/circuit-breaker/DLQ/idempotency
      behavior, new component, changed data model): `docs/architecture.md`
      reflects it, and a `docs/design/*.md` or `docs/decisions/*.md` (ADR)
      exists if the change actually meets that threshold — see the
      `architecture-docs` skill / `architecture-doc` agent /
      `/document-architecture` prompt.
- [ ] Before merging into `main`/`master`: an independent `merge-review`
      / `/merge-review` pass confirms the diff actually does what the PR
      claims (not just that it looks clean) and that the full branch —
      all commits combined — complies with the instructions files.

Automated parts of this (build, tests, secret scan) are enforced by the
`preToolUse` git-commit hooks in `.github/hooks/`, and destructive shell
commands (`git reset --hard`, force pushes to `main`/`master`, `rm -rf`,
etc.) are blocked on every shell call — not just at commit time — by the
Tool Guardian `preToolUse` hook (`guard-tool.sh`) in the same directory.
The judgment-based
parts (docs quality, scope, SOLID) are what the `quality-gate` agent /
`/validate` prompt checks — run it before considering non-trivial work
done, not just before a PR. Right before opening a PR, also run
`pre-pr-review` / `/pre-pr-review` — it checks instructions compliance,
best-practice consistency with the rest of the codebase, and hunts for
related places a change like this usually touches that got missed;
`quality-gate` doesn't cover that last part. Right before the PR merges
into `main`/`master`, run `merge-review` / `/merge-review` — unlike
`pre-pr-review` (the author's own pre-open check), this is meant to be
run independently of who wrote the change, and it's the only one of
these that checks whether the diff actually matches what it claims to
do.

## Coding conventions

Full Java/Spring Boot conventions live in
[`.github/instructions/java.instructions.md`](.github/instructions/java.instructions.md)
(auto-applied to `**/*.java`). PCI-DSS-specific handling rules live in
[`.github/instructions/security.instructions.md`](.github/instructions/security.instructions.md)
(auto-applied to payment/auth/card paths). Both stack additively with this
file — you don't need to repeat yourself by re-reading them here.

## Session continuity

Long-running or multi-session work tracks progress in `docs/progress.md`
using `RESUME_POINT` markers so a crashed or context-reset session can pick
back up without re-deriving prior work. See the `session-recovery` skill
(`.github/skills/session-recovery/SKILL.md`) for how to read/write it.

## Continuous improvement (retrospective loop)

When a bug escapes review or reaches production, and the root cause is
something an instructions file *should* have caught (a missing rule, an
ambiguous one, a check nobody thought to add), fixing the bug alone
leaves the gap open for the next person. Use `/retro` to propose a
specific, minimal addition to `java.instructions.md` or
`security.instructions.md` that would have caught this class of bug —
written for a human to review and apply, not auto-committed. Instructions
files are shared standards; changes to them get the same human sign-off
as any other change to what "correct" means for this codebase.

## Client support notes

As of Sept 2026 (this is a fast-moving preview surface — verify against
current docs before relying on it):

- **VS Code**: full feature set — this file, scoped instructions,
  prompts (`/name`), custom agents (`@name`), and skills all work; hooks
  are preview.
- **Copilot CLI**: this file, scoped instructions, custom agents, skills,
  and hooks all work — **but prompt files (`/name`) do not.** From CLI,
  invoke the agent directly (or just describe the task; the scoped
  instructions still auto-apply) instead of the `/command` shortcut this
  scaffold's prompts provide. CLI is also the only place the commit-time
  hooks actually fire.
- **IntelliJ (JetBrains Copilot plugin)**: this file and repo-wide/scoped
  instructions work; custom agents and prompts work in preview; hooks do
  not work. Don't rely on hooks catching anything when working from
  IntelliJ — the judgment-based checks (`quality-gate`,
  `security-reviewer`, `pre-pr-review`, `merge-review`) still apply, just
  run them explicitly.
