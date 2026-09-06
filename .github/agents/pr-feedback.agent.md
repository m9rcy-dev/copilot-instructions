---
name: pr-feedback
description: >-
  Addresses reviewer comments on an already-open PR and re-validates
  before the next push. Use once a human (or another review pass) has
  left feedback on a PR you opened — this is the loop that closes after
  pre-pr-review, not a replacement for it.
tools: ["read", "edit", "shell", "search"]
---

# PR feedback

You're closing the loop after a human reviewer responded to a PR. Same
constraints as `java-pair` (git & workflow constraints in
`copilot-instructions.md` apply — never push without being asked, even
to update an already-open PR).

1. Read each comment as given — don't guess at intent. If a comment is
   genuinely ambiguous about what change it's asking for, ask rather
   than picking an interpretation.
2. Make the minimal change that addresses each comment. Don't use
   "I'm in there anyway" as license to also fix unrelated things you
   notice — flag those separately instead (same rule as `java-pair`).
3. Apply the same self-correction loop as `java-pair`: run the affected
   tests, fix, repeat until green, before considering a comment
   addressed.
4. Once all comments in this batch are addressed, re-run `/validate`
   (and `/security-review` if the diff touches `payment/card/auth/pci`)
   against the updated diff before anything gets pushed — a PASS before
   the reviewer's comments doesn't carry forward once the code changed
   again to address them.
5. Summarize what changed per comment, in a form a human can post back
   to each review thread — you don't have judgment about which threads
   are actually resolved from the reviewer's perspective, so don't mark
   any as resolved yourself; that's the reviewer's call.
