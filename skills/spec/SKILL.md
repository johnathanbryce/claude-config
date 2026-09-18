---
description: Turn a rough feature idea into a structured one-page spec — problem, goals/non-goals, requirements, interface sketch, edge cases, open questions — and save it as a .md file that /scaffold, /architect pre, or any later session can build from and edit. Use when scoping a feature before code exists, or when a fuzzy idea needs to become buildable scope.
argument-hint: "[rough feature idea]"
allowed-tools: Read, Grep, Glob, Write, Edit, Bash(git rev-parse:*), Bash(git check-ignore:*)
disallowed-tools: Task, WebSearch, WebFetch
---

Turn this rough idea into a one-page spec: $ARGUMENTS

## Before writing

- If the idea touches an existing codebase, skim the relevant code first — a spec that contradicts the current architecture is worse than no spec. Skim means a handful of files (at most five); never crawl the repo, and never delegate the skim to a subagent.
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

## Output — ALWAYS a `.md` file (chat is ephemeral; the file is the source of truth)

The spec is the reference that `/scaffold`, `/architect pre`, and later sessions build from and
edit. It must live on disk, not only in chat.

**Where it goes** — decide in this order:

1. If I name a destination, use it.
2. Find the repo root with `git rev-parse --show-toplevel`. If `<root>/.local/` exists AND
   `git check-ignore -q .local` succeeds (it is not source-controlled), write to
   `<root>/.local/<slug>-spec.md`.
3. Otherwise write to `<root>/<slug>-spec.md` and flag it in the closing line:
   **"This file is at the repo root and is NOT gitignored — delete it (or move it into a
   gitignored `.local/`) before pushing."**
4. Not in a git repo: write to `./<slug>-spec.md` in the current directory, with the same flag.

`<slug>` is a short kebab-case name for the feature (e.g. `saved-filters-spec.md`). If the file
already exists, this is a revision: read it and update it in place rather than creating a second
one.

**In chat**: paste the spec, then end with one line giving the file path and, if it applies, the
delete-before-push flag. Tell me the path is what to pass to `/scaffold` or `/architect pre`.
