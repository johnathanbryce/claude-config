---
description: Convert an attached image (architecture screenshot, whiteboard photo, slide) or a written description into a Mermaid diagram in markdown — inserted into a named notes file or output to chat. Use when an image or concept needs to live in .md notes as a real rendered diagram instead of an image upload.
argument-hint: "[description and/or target .md file — or attach an image]"
allowed-tools: Read, Edit, Glob
---

Create a Mermaid diagram from this input: $ARGUMENTS

## Input

- An attached image (diagram screenshot, whiteboard photo, slide) — reproduce it faithfully.
- And/or a written description of what to diagram.
- If both are missing, or the source is ambiguous (unclear arrow direction, unreadable labels, unstated relationships), ask me 1-3 targeted questions before drawing — never guess silently.

## Output

- A fenced ```mermaid code block — GitHub renders these natively inside .md files.
- Pick the diagram type by content and say in one line which you picked and why: flowchart (architecture, request flow), sequenceDiagram (interactions over time), erDiagram (schemas/relationships), stateDiagram (lifecycles).
- If a target .md file is named or obvious from context, insert the diagram at the relevant section following that file's heading conventions; otherwise output to chat.

## Fidelity rules

- Reproduce what the source shows: same components, same labels, same connections. Never add components the source doesn't show, and never "improve" the architecture while transcribing it.
- If the source contains something Mermaid can't express cleanly, approximate it and flag the approximation in one line under the diagram.
- Node text is a label, not a sentence — keep it short.
