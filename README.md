# Copilot setup — Java / Spring Boot

A reusable `.github/` scaffold for GitHub Copilot, built for a Java/Spring
Boot backend where part of the codebase may be PCI-DSS (or similar
regulated-data) scoped. Drop `.github/` and `docs/progress.md` into a real
repo to use it there, then run `scripts/setup-project.sh` (see below) —
for now, both `.github/` and `docs/progress.md` are kept out of that
repo's commits, local-only.

## Layout

```
.github/
  copilot-instructions.md          # always-on, every client — keep this short
  instructions/
    java.instructions.md           # applyTo **/*.java
    security.instructions.md       # applyTo payment/card/auth/pci packages
  prompts/
    plan.prompt.md                 # /plan — write a phased plan before touching code
    new-endpoint.prompt.md         # /new-endpoint
    validate.prompt.md             # /validate — Definition of Done check
    security-review.prompt.md      # /security-review
    pre-pr-review.prompt.md        # /pre-pr-review — final holistic review
    pr-feedback.prompt.md          # /pr-feedback — address reviewer comments, re-validate
    merge-review.prompt.md         # /merge-review — arms-length check before merge to main/master
    document-architecture.prompt.md # /document-architecture — architecture.md, detailed designs, ADRs
    retro.prompt.md                # /retro — propose an instructions-file fix after an escaped bug
    session-resume.prompt.md       # /session-resume
  agents/
    planner.agent.md               # @planner — read-only, produces a phased plan (also backs /retro)
    java-pair.agent.md             # @java-pair — default dev persona, implements, self-corrects
    quality-gate.agent.md          # @quality-gate — read-only, Definition of Done check
    security-reviewer.agent.md     # @security-reviewer — read-only, PCI-focused review
    pre-pr-review.agent.md         # @pre-pr-review — read-only, author's own pre-open check
    pr-feedback.agent.md           # @pr-feedback — addresses PR review comments, re-validates
    merge-review.agent.md          # @merge-review — read-only, independent intent + guideline check before merge
    architecture-doc.agent.md      # @architecture-doc — architecture.md + docs/design/ + docs/decisions/, never source code
  skills/
    session-recovery/SKILL.md      # docs/progress.md crash-recovery pattern
    architecture-docs/SKILL.md     # methodology: 12-section template, reliability math, when to write a detailed design/ADR
      references/architecture-template.md
      references/detailed-design-template.md
      references/adr-template.md
      references/sla-calculation.md  # SLA timing + DLQ + idempotency
  hooks/
    hooks.json
    scripts/
      scan-secrets-pretooluse.sh    # fail-closed secret gate on `git commit`
      quality-gate-pretooluse.sh    # fail-closed build+test gate on `git commit`
      scan-secrets-sessionend.sh    # best-effort audit log backstop
  workflows/
    ci.yml                          # outer loop — same checks, server-side, independent of local hooks
docs/
  progress.md                      # RESUME_POINT log, used by session-recovery
  architecture.md                  # 12-section system summary — generated/maintained, not hand-authored
  design/                          # detailed design docs, linked from architecture.md §12
  decisions/                       # ADRs, linked from architecture.md §11
scripts/
  setup-project.sh                 # gitignore + untrack .github/ (except workflows/) + docs/progress.md
```

## What works where

As of this writing (Sept 2026), per GitHub's own customization cheat
sheet plus open `github/copilot-cli` issues — this is a fast-moving
preview surface, re-check against current docs before relying on it:

| Feature | VS Code | JetBrains (IntelliJ) | Copilot CLI |
|---|---|---|---|
| `copilot-instructions.md` | yes | yes | yes |
| scoped `instructions/*.md` | yes | yes (preview) | yes |
| `prompts/*.prompt.md` | yes | preview | **no** |
| `agents/*.agent.md` | yes | preview/GA | yes |
| `skills/` | yes | preview | yes |
| `hooks/` | preview | no | yes |

Two things worth being deliberate about:

- **`copilot-instructions.md` is still the one file guaranteed
  everywhere** — that's why the non-negotiables live there rather than
  in a prompt or agent file.
- **Prompt files don't work in Copilot CLI at all** — and CLI is the
  *only* surface where the commit-time hooks in this scaffold actually
  fire. That means from Copilot CLI, none of `/plan`, `/validate`,
  `/pre-pr-review`, `/security-review`, `/pr-feedback`, `/merge-review`,
  `/retro`, `/new-endpoint`, or `/session-resume` work as slash commands
  — but the underlying agents they're bound to (`@planner`,
  `@quality-gate`, etc.) are still supported there. From CLI, invoke the
  agent directly (or just describe the task — the relevant
  `instructions/*.md` still auto-apply) instead of reaching for the
  `/command`. JetBrains is the mirror case: prompt files and agents work
  there (in preview) even though the hooks don't.

## Workflow: plan → implement → validate → pre-PR review → PR feedback → merge review

Each step below is a closed loop, not a one-shot pass — a check that
fails hands back to fix-and-recheck rather than stopping at a report.

1. **Plan** (`/plan`, `@planner`) — read-only, no edits. Turns a request
   into a written plan for you to review before any code changes: goal,
   approach, an ordered breakdown into discrete implementation steps
   (each independently reviewable/validatable — for larger plans, a
   candidate `session-recovery` checkpoint), PCI scope, test plan, and
   risks. Skip for trivial one-line fixes; use it for anything touching
   more than a file or two.
2. **Implement** (`@java-pair`, or no prompt needed — it's the default
   persona) — makes the actual changes, following
   `instructions/java.instructions.md` and, where relevant,
   `instructions/security.instructions.md`. For a multi-step plan,
   implement and validate one step at a time rather than the whole plan
   at once. **Inner loop:** java-pair runs the affected tests itself and
   fixes failures before reporting a step done — it doesn't hand off
   code it hasn't actually run.
3. **Validate** (`/validate`, `@quality-gate`) — read-only, checks the
   diff against the Definition of Done checklist in
   `copilot-instructions.md` (build, tests, docs, Clean Code/SOLID,
   scope), actually running the build/tests rather than trusting claims.
   On BLOCKED: fix, then re-run `/validate` against the updated diff —
   a PASS only counts for the diff it was actually run against.
4. **Pre-PR review** (`/pre-pr-review`, `@pre-pr-review`) — read-only,
   the final gate right before opening a PR: checks instructions
   compliance clause by clause, consistency with how similar existing
   code in the repo does the same kind of thing, and specifically hunts
   for missed integration points (a mapper, an API doc entry, an
   exception-advice registration, a sibling implementation) that a
   change of this shape usually also needs but this diff didn't touch.
   It does not repeat `quality-gate`'s checklist or `security-reviewer`'s
   PCI checks — run those first. Same BLOCKED → fix → re-run loop.
5. **PR feedback** (`/pr-feedback`, `@pr-feedback`) — after a human
   reviewer comments on the open PR, addresses each comment, re-runs the
   self-correction loop, then re-runs `/validate` (and `/security-review`
   if applicable) before the next push. Closes the loop that steps 1–4
   don't cover: what happens *after* the PR is open.
6. **Merge review** (`/merge-review`, `@merge-review`) — read-only,
   independent of who wrote the change (unlike `pre-pr-review`, which is
   the author's own pre-open check). Runs against the full branch/PR
   right before it merges into `main`/`master`: checks whether the diff
   actually does what the PR title/description/commits claim (not just
   whether it looks clean), full-branch compliance with the instructions
   files across all commits combined, and merge-specific risk (breaking
   changes, cross-PR dependencies). This is the check most naturally run
   by whoever is *approving* the merge, not the author.

For anything under `payment/card/auth/pci`, also run `/security-review`
(`@security-reviewer`) — orthogonal to the steps above, not a
replacement for any of them.

The mechanical parts of this (build, tests, secrets) are also enforced
at commit time by the `preToolUse` hooks, and again server-side by the
CI workflow (see below) — `/validate` and `/pre-pr-review` are the
judgment-based checks you run *before* either of those, so you're not
relying on a hard gate to catch things a review would've caught earlier.

**Retrospective loop:** if a bug escapes this whole pipeline and reaches
review or production, use `/retro` (see "Continuous improvement" in
`copilot-instructions.md`) to propose the specific instructions-file
addition that would have caught it — a human still approves the change,
but the gap doesn't just get patched once and left open for next time.

## Documentation strategy: as-you-go vs. after

Two different kinds of documentation, deliberately handled differently:

- **Code-level (Javadoc, inline intent) — as-you-go, non-negotiable.**
  `java.instructions.md` requires it as part of the change itself, not a
  follow-up; `quality-gate`/`pre-pr-review` verify it's there before a
  change counts as done. There's no "document it later" for this tier —
  a change without it isn't finished.
- **System-level (`docs/architecture.md` + `docs/design/` +
  `docs/decisions/`) — as-you-go for the section/document that changed,
  plus periodic full regeneration as a safety net.** `docs/architecture.md`
  is a 12-section system-level summary (overview, layered architecture,
  components, data flow, external systems, data architecture, security,
  deployment, reliability, observability) that stays one page and links
  *out* rather than growing without bound — §11 indexes ADRs in
  `docs/decisions/`, §12 indexes detailed design docs in `docs/design/`,
  for the flows/decisions too deep for a one-page summary to hold. Most
  changes need only the summary updated; a detailed design or ADR is only
  warranted when the `architecture-docs` skill's threshold is actually
  met (a genuinely contested decision, a flow too complex to summarize
  faithfully) — `planner` flags this during planning, `pre-pr-review`
  flags it if a change met the threshold but skipped it. Separately,
  `/document-architecture` (`@architecture-doc`, backed by the
  `architecture-docs` skill) does a full codebase scan to (re)generate
  the whole summary — use it for initial creation on an existing
  codebase, or a periodic audit to catch drift the per-change gate
  missed. `architecture-doc` only ever touches those three doc locations,
  never source code, and every fact/decision it records must trace to
  something actually found in the code or actually decided — no invented
  dependencies, guessed SLA numbers, or retroactive ADR rationale.

## Keeping the scaffold out of the target repo's commits

`scripts/setup-project.sh` gitignores `.github/` (except
`.github/workflows/` — see below) and `docs/progress.md` in whatever repo
you run it from (updates `.gitignore`, and untracks any of those paths
from git's index if already added or committed — without touching the
files on disk). Run it after copying this scaffold into your real
project:

```bash
# from the root of your target project, after copying .github/ and
# docs/progress.md in:
/path/to/this/template/scripts/setup-project.sh
```

It never commits or pushes anything itself — if it untracks something
already-committed, that change is left staged for you to review
(`git status`, `git diff --cached --stat`) and commit yourself.

This is a **current, revisitable choice**, not a permanent architectural
one: local Copilot clients (VS Code, IntelliJ, CLI) read these files off
disk regardless of git-tracking status, so ignoring them doesn't break
anything for you locally — it just means the setup won't sync to
teammates through this repo's git history until/unless that's revisited
and the files are committed instead. If a path was committed *before*
running the script, it still exists in earlier commits — the script only
stops it from being included in future ones; that's a separate,
deliberate history-rewrite decision if it's ever needed.

**Why `.github/workflows/` is the one exception:** GitHub Actions only
runs workflow files that are actually committed on the branch/PR being
built — a gitignored `ci.yml` would simply never execute, so it can't be
treated the same as the rest of `.github/`. The script excludes
`.github/`'s contents individually (`/.github/*` + `!/.github/workflows/`)
rather than the directory as a whole, specifically so this carve-out
works — a plain `/.github/` pattern would block it, since git can't
re-include a path nested inside an already-excluded parent directory.

## Setting up the commit-time hooks

Both `preToolUse` hooks reliably work in Copilot CLI / cloud agent; VS
Code support is preview and JetBrains doesn't support hooks at all. A
commit made from an editor's own git UI, or from JetBrains, bypasses them
entirely regardless — so don't treat them as the only gate; that's what
the [outer-loop CI workflow](#outer-loop-ci-workflow) and the judgment-based
review agents (`quality-gate`, `pre-pr-review`, `merge-review`) are for.

- **`scan-secrets-pretooluse.sh`** prefers
  [`gitleaks`](https://github.com/gitleaks/gitleaks) if installed
  (`brew install gitleaks`) and falls back to a small built-in regex set
  otherwise — install gitleaks for real coverage, the fallback is a
  backstop, not a replacement.
- **`quality-gate-pretooluse.sh`** runs the project's actual build/test
  command (`mvn verify` or `./gradlew check`, auto-detected) and blocks
  the commit if it fails. This runs the full suite on every commit,
  which can be slow — that's a deliberate fail-closed tradeoff; CI is
  still the final authority regardless, this is a local backstop. If
  neither `pom.xml` nor `build.gradle(.kts)` is found it passes through
  with a warning rather than blocking, since it can't assume the build
  layout.

```bash
chmod +x .github/hooks/scripts/*.sh   # already done in this template
```

Hooks are wired via `.github/hooks/hooks.json`. Verify your Copilot CLI
version actually loads hooks from that path — the hook system is newer
and the exact discovery path/schema may shift; check
`copilot --help` / current docs if hooks don't seem to fire.

## Outer loop: CI workflow

`.github/workflows/ci.yml` re-runs the same build/test/secret-scan
checks as the local hooks, but server-side on every PR — independent of
whether Copilot CLI (or any AI tooling) was involved in the commit at
all. This is the gap the local-only hooks can't close on their own: a
commit made from VS Code's built-in git UI, or by a human with no
Copilot involved, hits zero automated check without this.

It must be committed to have any effect (see the workflows/ carve-out
above) — adjust the JDK version in the workflow file to match your
project before relying on it.

## Extending

- Full-length policy documents (complete PCI-DSS policy text, full style
  guide) belong as a skill's bundled `references/` file, not pasted into
  an instructions file — keep `copilot-instructions.md` well under the
  ~1000 line soft cap and scoped instructions focused.
- Browse [`github/awesome-copilot`](https://awesome-copilot.github.com)
  for more prompts/agents/skills/hooks to install
  (`copilot plugin install <name>@awesome-copilot`), including a fuller
  secrets-scanner hook example and an
  `acreadiness-generate-instructions` skill that can (re)generate
  instructions files from an existing codebase.

## Adapting this scaffold to a different domain

This scaffold currently assumes a payments/cards domain — that shows up
as one repeated concept, not scattered special-casing: a
"regulated/sensitive-data package glob" (`payment/`, `card/`, `auth/`,
`pci/`) plus PCI-DSS as the specific named framework governing it. Most
of the scaffold doesn't depend on that at all:

**Transfers unchanged, regardless of domain:** the whole workflow
(`plan`/`java-pair`/`quality-gate`/`pre-pr-review`/`pr-feedback`/
`merge-review`), both commit-time hooks, the CI workflow,
`session-recovery`, and the `architecture-docs` skill's core methodology
(diagrams, config sourcing, SLA/DLQ/idempotency math). None of it assumes
payments — leave it alone.

**Cosmetic only:** a few examples in `java.instructions.md`
(`PaymentException`, a `"Payment {} declined"` log line, `payment/` used
as an example of "package by feature") are stand-ins for a generic rule,
not the rule itself. Swap the example, keep the rule.

**The one real coupling point — and the question to answer first:**
does your new domain have *any* class of code that needs rules beyond
generic good Java practice, scoped to specific packages? That's what
`security.instructions.md` + the `security-reviewer` agent are *for* —
PCI-DSS is just this scaffold's current instance of that slot. A
different domain's instance of that slot isn't necessarily a compliance
framework at all — it could be query-complexity/DoS limits on unbounded
traversals for a graph service, multi-tenant data isolation, PII
handling under GDPR, PHI handling under HIPAA, or genuinely nothing if
the new domain has no such category. Don't force-fit a framework that
doesn't exist for your new domain.

**If yes, something fills that slot** — rewrite, don't find-replace:

1. Decide the new sensitive-scope package glob (e.g. `entity/`,
   `resolution/`, `pii/` for a graph-engineering service handling
   entity-resolution data under GDPR) and replace `payment/card/auth/pci`
   with it everywhere it appears — that part genuinely is a mechanical
   find-replace, across: `copilot-instructions.md`,
   `security.instructions.md`'s `applyTo`, `java.instructions.md`,
   `java-pair.agent.md`, `planner.agent.md`, `quality-gate.agent.md`,
   `pre-pr-review.agent.md`, `merge-review.agent.md`, `pr-feedback.agent.md`,
   `new-endpoint.prompt.md`, `plan.prompt.md`, `validate.prompt.md`,
   `architecture-docs/SKILL.md`, this README.
2. Rewrite `security.instructions.md`'s actual content from scratch for
   the new framework/concern — its PAN/CVV/tokenization rules are
   PCI-DSS-specific and won't transfer; what transfers is the *shape*
   (non-negotiables, logging/telemetry rules, authN/authZ rules,
   input-validation rules, dependency-scanning rules).
3. Rewrite `security-reviewer.agent.md` and `security-review.prompt.md`
   the same way — the checklist is PCI-specific; the read-only,
   "report findings with severity, don't self-approve" *pattern* is what
   transfers.
4. Update the non-negotiables in `copilot-instructions.md` — "card
   numbers (PAN), CVV, or full account numbers" is the payments instance
   of "don't leak this category of sensitive value"; name your new
   domain's actual sensitive-value category there instead.

**If no, nothing fills that slot** — delete rather than leave stale
references: `security.instructions.md`, `security-reviewer.agent.md`,
`security-review.prompt.md`; then strip every `payment/card/auth/pci`
reference and every `security-reviewer`/`/security-review` cross-mention
from the files listed in step 1 above, plus the Definition of Done
checklist item in `copilot-instructions.md`. A stale reference to a
review gate that no longer exists is worse than no gate — it reads as a
promise nothing enforces.

Either way, `docs/architecture.md` §7 (Security) stays — it documents
*what's actually implemented*, which is true in any domain — but it
should link to whatever `security.instructions.md` becomes (or note
plainly that this domain has no such file, rather than link to one that
no longer exists).

## Session continuity

For work spanning multiple sessions, see `.github/skills/session-recovery/SKILL.md`
and `docs/progress.md`. Invoke `/session-resume` at the start of a new
session on ongoing work.
