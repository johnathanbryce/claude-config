---
description: Scaffold the mechanical structure for a feature or project — files, directories, imports, UI markup, config, stubs — while leaving ALL logic as TODO stubs for John to implement. Use when asked to "scaffold", "set up the structure/boilerplate for", or "stub out" a feature or project.
argument-hint: "[light|medium|heavy] [path/to/<slug>-spec.md] [description]  — MANUAL: pick model + effort in /model BEFORE running; this skill never sets them"
allowed-tools: Read, Glob, Grep, Write, Edit, Bash(mkdir:*)
disallowed-tools: Task, WebSearch, WebFetch
---

# Scaffold

Generate the mechanical structure for whatever is described. NEVER write logic. Logic is
anything with control flow, a query, or a data transformation — it arrives as a stub marked
`TODO(John)`, no matter how simple it looks. John writes all logic himself; that is the point
of this skill.

## Input

`$ARGUMENTS` is an optional dial level, then an optional path to a spec `.md`, then an optional
description. The spec file (written by `/spec`) is the source of truth for the build — always
find it before scaffolding, in this order:

1. A `.md` path in `$ARGUMENTS` — read it.
2. A spec written or referenced earlier in this conversation (usually `/spec` ran in this same
   session) — use that file, re-reading it from disk in case it was edited.
3. Otherwise glob for `*-spec.md` in `.local/` and the repo root. Exactly one match → confirm
   it's the right one in a single line before proceeding. Zero or several → ask me which spec
   (or whether to proceed from a description alone). Never guess.

If there is no spec and the description alone doesn't give enough to scaffold confidently, ask
2-3 targeted questions instead of guessing.

## Dial (default: medium)

- **light** — files/directories, imports, empty function/component stubs. Skeleton only.
- **medium** — light + UI markup/CSS + function signatures with docstrings/props and `TODO(John)` stub bodies.
- **heavy** — medium + config/dependency manifests, type/schema shells, test-runner setup (config
  only, e.g. `jest.config`, `conftest.py`), seed data.

**Tests are not scaffolded at any level.** No test files, no named test cases — that is
`/unit-tests` (its `scaffold` mode writes stub cases). At most, mention in the manifest that
`/unit-tests` is the next step once the logic is written.

The dial only controls how much mechanical structure is generated. It never moves the logic
boundary — logic is stubbed at every level.

## Manifest gate (mandatory)

Before writing anything, print the proposed file tree with one line per file stating what will
be generated vs. what is stubbed for John. Flag anything borderline as an explicit question in
the manifest (e.g. a schema that might be this session's learning target). Wait for approval,
then build exactly the approved manifest — nothing more.

## Rules

- Stub bodies must fail loudly: `raise NotImplementedError("TODO(John)")` in Python,
  `throw new Error("TODO(John)")` in TS/JS — never a silent `pass` or empty return.
- When unsure whether something is structure or logic: stub it and flag it in the manifest.
- When scaffolding into an existing project, match its conventions (layout, naming, style).
- Never scaffold something John is actively learning — if the request overlaps a stated
  learning target, flag it in the manifest instead of generating it.

## After building

If a spec file was used, append a short `## Scaffolded` section to it: the date, the dial, the
files created, and any items stubbed-and-flagged. The spec stays the running plan for the build.
