---
description: Turn a rough feature idea into a structured one-page spec — problem, goals/non-goals, requirements, interface sketch, edge cases, open questions. Use when scoping a feature before code exists, or when a fuzzy idea needs to become buildable scope.
argument-hint: "[rough feature idea]"
allowed-tools: Read, Grep, Glob
---

Turn this rough idea into a one-page spec: $ARGUMENTS

## Before writing

- If the idea touches an existing codebase, skim the relevant code first — a spec that contradicts the current architecture is worse than no spec.
- If the idea is too vague to scope (no identifiable user or behavior), ask me at most 2-3 clarifying questions before writing. Otherwise write first and park uncertainty in Open Questions.

## The spec — one page, these sections, in order

1. **Problem** — what's missing or broken, for whom, and why now. Two or three sentences.
2. **Goals** — the outcomes v1 must deliver, as bullets. Measurable where possible.
3. **Non-goals** — what this deliberately will NOT do. Be aggressive; this section is where scope creep dies.
4. **Requirements** — the behaviors, numbered so review can reference them.
5. **Interface sketch** — endpoints/functions/UI surface with request and response shapes. Sketch-level, not final.
6. **Edge cases** — failure modes and boundary conditions that must be decided, each with a proposed answer.
7. **Open questions** — decisions still unmade, each framed with a recommendation, not just a question.

## Voice and rules

- Write like an engineer scoping their own work: plain sentences, no marketing language, no filler.
- Every requirement must be concrete enough to test. "Should be fast" is not a requirement; "list endpoints return in <200ms at 10k rows" is.
- Prefer cutting scope to padding it — a spec that fits on one page gets read.
- Output to chat by default; write to a file only when I name a destination.
