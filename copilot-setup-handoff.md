# Handoff: GitHub Copilot Customization Setup

Context carried over from a claude.ai chat, for continuing in Claude Code.

## Goal
Set up/refine a GitHub Copilot workflow for a Java/Spring Boot backend
(commercial cards team, PCI-DSS relevant), covering instructions, prompts,
agents, skills, and hooks — building on an existing system that already has
global/path instructions, prompt files, custom agent personas, and a
docs/progress.md crash-recovery pattern with RESUME_POINT markers.

## Concepts covered (mechanics, for reference)

- **Instructions** (`.github/copilot-instructions.md` + `.github/instructions/*.instructions.md`
  with `applyTo` globs) — always-on, auto-injected, no invocation needed.
  Discovered automatically per file touched; multiple matching instruction
  files stack (additive), they don't override each other. Keep
  `copilot-instructions.md` short (~1000 line soft cap, some tools truncate
  earlier); push long reference material into skills instead of pasting it
  into instructions.
- **Prompts** (`.github/prompts/*.prompt.md`) — manual, invoked via `/name`
  in chat. Frontmatter can bind a prompt to a specific `agent:` so invoking
  it auto-delegates to that agent.
- **Agents** (`.github/agents/*.agent.md`, formerly `.chatmode.md`) — persona
  + tool restrictions. Invoked via `@name` (VS Code), `/agent` (CLI), or
  auto-delegated when a request matches an agent's description.
- **Skills** (`.github/skills/<name>/SKILL.md`, Agent Skills spec) —
  self-contained, on-demand. Triggered by (a) automatic description
  matching, (b) manual `/skill-name` slash command (skills appear in the
  same picker as prompts), or (c) referenced as a dependency by another
  agent/prompt. Support bundled assets (`references/`, `scripts/`,
  `assets/`) — the right place for large documents (full security policies,
  style guides) that would bloat an always-on instructions file.
- **Hooks** (`.github/hooks/*.json`) — external shell commands firing at
  session lifecycle events (`sessionStart`, `sessionEnd`,
  `userPromptSubmitted`, `preToolUse`, `postToolUse`, `errorOccurred`,
  `permissionRequest`). Supported in Copilot CLI and cloud agent, not VS
  Code chat. `preToolUse` hooks can fail-closed (exit 2 blocks the tool
  call outright) — this is the mechanism for an actual pre-commit secret
  scan gate, not just a post-hoc `sessionEnd` audit log.

## Reference repo
`github/awesome-copilot` — officially maintained, browsable at
awesome-copilot.github.com, installable via
`copilot plugin install <name>@awesome-copilot`. Has a `Secrets Scanner`
hook example (`sessionEnd`, `scan-secrets.sh`) and an
`acreadiness-generate-instructions` skill that can generate
copilot-instructions.md + scoped instructions files from an existing
codebase/standards.

## Artifact produced this session
A sketch `SKILL.md` for wrapping the docs/progress.md + RESUME_POINT
crash-recovery pattern as a proper Agent Skill (`session-recovery`) —
see attached file if carried over, otherwise regenerate from this summary.

## Status: scaffold built (2026-09-06)

All three open items above are done — see `README.md` for the full layout.
Built as a generic reusable template (not tied to a specific existing repo),
since this working directory started empty. Summary of what exists now:

- `.github/hooks/hooks.json` + `scan-secrets-pretooluse.sh` (fail-closed
  gate on `git commit`, gitleaks-preferred with regex fallback) +
  `scan-secrets-sessionend.sh` (non-blocking audit backstop).
- `.github/copilot-instructions.md` (short, non-negotiables only) +
  `.github/instructions/java.instructions.md` (applyTo `**/*.java`) +
  `.github/instructions/security.instructions.md` (applyTo
  `**/{payment,card,auth,pci}/**/*.java`). Full PCI-DSS policy text is
  intentionally NOT pasted in anywhere — noted as a TODO to add as a
  skill reference doc when the real policy text is available.
- Also added (beyond the original 3 items, since building the full
  scaffold): example `agents/java-pair.agent.md` and
  `agents/security-reviewer.agent.md`, prompts (`new-endpoint`,
  `security-review`, `session-resume`), and the `session-recovery` skill
  + `docs/progress.md` template.

## Next items (not yet done)

- Not a git repo yet — `git init` + commit when ready to version this.
- Real PCI-DSS policy text/control mappings not yet added anywhere (see
  the placeholder note in `security.instructions.md`) — add as a skill
  reference file, don't paste into the instructions file.
- Hook schema/paths in `hooks.json` are written from the mechanics
  described in the original claude.ai chat, not verified against a live
  Copilot CLI install — confirm hooks actually fire before relying on
  the commit gate.
- This scaffold hasn't been copied into / tried against a real Spring
  Boot repo yet.
