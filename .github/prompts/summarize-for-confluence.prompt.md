---
description: Summarize an architecture/design doc into a condensed, Confluence-ready page.
agent: confluence-summarizer
---

Summarize ${input:doc:the document(s) to summarize — e.g. docs/architecture.md, or a specific docs/design/*.md or docs/decisions/*.md} into a Confluence-ready page.

Read the full source document(s) first. Follow the
`confluence-summarizer` agent's format (source line, title,
one-paragraph summary, body sections, tables where the source has
tabular data) and note explicitly anything cut for length.

Do not invent content beyond what the source document states, and do
not edit the source document itself.
