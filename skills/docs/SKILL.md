---
description: Write documentation for the work on the current branch — analyzes the branch diff plus uncommitted changes and creates/updates a feature doc in the repo's docs/ directory, or produces a PR description with "pr". Use when finished work needs documentation or a PR write-up.
argument-hint: "[pending] [pr]"
allowed-tools: Read, Grep, Glob, Write, Edit, Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git merge-base:*), Bash(git branch:*)
---

Document the work on this branch.

## Arguments

$ARGUMENTS may contain, in any order:

- `pending` — scope to uncommitted changes only. Default: the full branch — every commit since it diverged from the default branch (`git diff $(git merge-base <default-branch> HEAD)`) PLUS uncommitted changes. If currently ON the default branch, fall back to uncommitted changes only and say so in the report.
- `pr` — produce a PR description instead of a feature doc.

## Process

1. Establish scope per the arguments (use `git status --porcelain --untracked-files=all` for uncommitted work — untracked directories otherwise collapse to one line and their files are missed).
2. Read every in-scope source file in full — documentation written from hunks alone is guesswork.
3. Produce the artifact for the chosen mode below.

## Feature doc mode (default)

- Location: the repo's `docs/` directory (create it if absent). One doc per feature/area, kebab-case filename.
- **Update in place:** if a doc already covers the touched area, edit that doc — never create a parallel `-v2` file. Match the existing doc's structure and voice.
- Contents, in order:
  1. Title + one-paragraph summary — what this is and why it exists.
  2. How to use it — commands, endpoints, or calls with realistic examples.
  3. Interface reference — endpoints/functions with inputs, outputs, and error responses.
  4. Behavior notes — edge cases, defaults, and decisions a user would otherwise discover the hard way.
  5. Known limitations / gotchas.

## PR description mode (`pr`)

Output to chat (for copy-paste), not to a file:

1. **Summary** — the why and the what, two or three sentences.
2. **Changes** — grouped by area, described at the behavior level.
3. **How it was tested** — actual evidence (test runs, manual verification), never claims.
4. **Notes for reviewers** — risk areas, decisions that deserve scrutiny, follow-ups deliberately left out.

## Hard rules

- Document **behavior and usage**, never narrate the diff — "changed line 42 of store.py" is a changelog entry, not documentation.
- Never invent behavior. Every claim must be verifiable in the code that was read; if something is ambiguous, flag it as an open question rather than writing plausible filler.
- No aspirational docs: describe what the code does today, not what it should do eventually.
- Brevity is a feature. Capture only what a reader needs to use or maintain the thing — no restating the obvious, no filler prose, no boilerplate sections. If a section would be empty or self-evident, omit the section. When in doubt, cut.

## Report

What was written or updated and where, what was deliberately excluded from scope, and any open questions flagged.
