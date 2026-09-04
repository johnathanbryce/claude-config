---
description: End-of-build report — explain everything that was just built or changed and why, ranked by importance. Use at the end of an AI-driven build/pipeline when asked to "explain what you did", "summarize the changes", or "walk me through what was built".
allowed-tools: Read, Grep, Glob, Bash(git diff:*), Bash(git log:*), Bash(git status:*)
---

# Explain

Orient John in a result he didn't write line by line. Chat only — never writes files.
Report, not review: no fixes, no suggestions, no quality verdicts (that's `/diff-review`).

## Source of truth

- **What changed**: uncommitted work (`git status --untracked-files=all`, so new dirs aren't missed) + branch diff vs main.
- **Why it changed**: this session — decisions made, options rejected, rulings John gave.
- No changes found → say so and stop.

## Output

Bullets only. No prose paragraphs, no file-by-file narration.

**TL;DR** — 1–2 sentences: what got built, in plain language.

**Changes** — ranked by what would bite John first if he didn't know it existed. One line each:
- `**what** — why. [file.ts:42](file.ts#L42)`
- Order: architectural decisions and behavior changes → new deps/config → mechanical changes.
- Mechanical changes collapse into a single trailing bullet ("renames, formatting, imports across 6 files").

**New in the codebase** — first appearance of a pattern, library, seam, or convention. One line: what it is, why it was chosen. Omit the section if nothing is new.

**Next steps** — only if John must act (run a migration, install a dep, set an env var, fill a stub). Numbered, imperative. Omit entirely if nothing is required.

## Rules

- Hard cap ~10 bullets. If a change wouldn't alter how John works with the code, it gets one line or none.
- Every "why" must be a decision that was actually made. Unknown → "unclear from session". Never invent rationale.
- Lead with the decision, not the diff.
- Written for John right now, not for the repo — `/docs` is the durable artifact.
