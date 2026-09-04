---
description: Scaffold the mechanical structure for a feature or project — files, directories, imports, UI markup, config, stubs — while leaving ALL logic as TODO stubs for John to implement. Use when asked to "scaffold", "set up the structure/boilerplate for", or "stub out" a feature or project.
argument-hint: "[light|medium|heavy] what to scaffold"
allowed-tools: Read, Glob, Grep, Write, Bash(mkdir:*)
---

# Scaffold

Generate the mechanical structure for whatever is described. NEVER write logic. Logic is
anything with control flow, a query, or a data transformation — it arrives as a stub marked
`TODO(John)`, no matter how simple it looks. John writes all logic himself; that is the point
of this skill.

## Input

`$ARGUMENTS` is an optional dial level followed by a description. If no description is given,
scaffold from the current conversation or spec context. If neither gives enough to scaffold
confidently, ask 2-3 targeted questions instead of guessing.

## Dial (default: medium)

- **light** — files/directories, imports, empty function/component stubs. Skeleton only.
- **medium** — light + UI markup/CSS + function signatures with docstrings/props and `TODO(John)` stub bodies.
- **heavy** — medium + config/dependency manifests, type/schema shells, test-runner setup, seed data.

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
