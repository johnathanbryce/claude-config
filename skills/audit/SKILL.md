---
description: Deep-dive an unfamiliar or un-audited repo and produce an orientation + health report — what the app is, how to run it, its architecture, its debt and landmines, and its dependency risks. Delegates the dependency-currency sweep to the `deps-auditor` subagent (web-researched, not from memory). Use when you JUST joined a repo, inherited a half-built codebase, or want to audit a project you've worked in but never health-checked. Distinct from /init (which only documents structure) and deep-code-review (which reviews a diff, not the whole repo). Read-only except for the report file it writes.
argument-hint: "[path to repo — defaults to cwd] [no-deps to skip the dependency sweep]"
allowed-tools: Read, Grep, Glob, Task, Write, Edit, Bash(git status:*), Bash(git log:*), Bash(ls:*), Bash(find:*), Bash(cat:*), Bash(wc:*), Bash(rg:*), Bash(head:*)
---

Audit this repo: $ARGUMENTS

Default target is the current directory. If a path is given, scope to it. `no-deps` skips the
dependency subagent (use when offline or when you only want the orientation half).

You are orienting a new engineer to an unfamiliar codebase AND flagging its health. Be the person who
read the whole repo so they don't have to. Ground every claim in files you actually read — never
narrate what a repo "probably" does.

## 1. Map the app

- Read the README, top-level config, and entry points. Identify: **what this app does** (purpose /
  domain), the **stack** (languages, frameworks, datastores, external services), and the **shape**
  (monolith / service / library / monorepo).
- Find the **entry points** (main, server bootstrap, CLI, route roots) and the **key directories** —
  where the real logic lives vs. generated/vendored/config noise.

## 2. How to run it

Discover the actual commands — from `package.json` scripts, `Makefile`, `pyproject.toml`,
`docker-compose.yml`, CI config, or the README: **install · run (dev) · test · build**. If a command
can't be determined, say so rather than guessing one that won't work.

## 3. Health & debt scan

- **TODOs/landmines:** grep `TODO|FIXME|HACK|XXX|@deprecated` — count them, surface the notable ones
  with `file:line`.
- **Tests:** do they exist, what framework, and roughly how much surface do they cover (a signal, not
  a coverage number) — or is there none?
- **Config / secrets smells:** committed `.env`, hardcoded keys/tokens, credentials in source, and
  plaintext secrets sitting in on-disk `.env` files. **NEVER echo a secret's value.** When you find
  one, report its presence by variable name and a masked prefix only (e.g. `ANTHROPIC_API_KEY=sk-ant-…`,
  `AWS_ACCESS_KEY_ID=AKIA…`) — never the full string, in chat or the report file. Printing live key
  material into output is itself a leak. Also check `git log --all` to distinguish a real git-history
  leak (serious) from a gitignored local `.env` (expected in a dev tree).
- **Rot:** large commented-out blocks, obviously dead code, duplicated logic, convention drift
  (mixed module styles, mixed formatting) that signals no shared standard.

## 4. Dependency risks — delegate to the subagent

Unless `no-deps` was passed, spawn the **`deps-auditor`** subagent (via the Task tool) pointed at
this repo. It reads the manifests/lockfiles, web-researches each direct dependency, and hands back the
outdated / deprecated / EOL / security-advisory findings plus the specific deprecated APIs to grep for.

When it returns: **take the deprecated APIs it named and grep the codebase** to see whether they are
actually used. A deprecated method the repo never calls is a footnote; one used in `file:line` is a
real finding — report it as such. This usage check is yours to do, not the subagent's.

If the subagent returns nothing usable (offline, private packages), note that in the report and move on
— don't block the whole audit on it.

## 5. Write the report + summarize

Write to **`repo-audit.md`** in the repo root (or a named destination). This is a **personal
orientation artifact** — note at the top that it's not meant to be committed to a repo you just joined;
gitignore or delete it. Update in place if it already exists; never a parallel `-v2`.

Report sections, in order:

1. **What this is** — purpose + stack, one tight paragraph.
2. **How to run it** — install / run / test / build commands.
3. **Map** — key directories + entry points, architecture in prose. (Note: run `/architect post` or
   point `/architect` at the repo for a rendered diagram — this report stays prose.)
4. **Health & debt** — TODOs, test coverage signal, config/secrets smells, rot. Most important first.
5. **Dependency risks** — the subagent's criticals, plus which deprecated APIs are actually used in
   code (`file:line`). Full dependency table can go in an appendix.
6. **Where to start** — if you were picking this up Monday, the 3-5 things to read/fix/verify first.

Then in chat: the mode line, the report path, and a **5-line executive summary** — what the app is, its
single biggest health risk, and the top dependency finding. Don't paste the whole report into chat;
it's in the file.

## Rules

- Read before you assert. Every claim traces to a file you opened or a command you found.
- Prioritize ruthlessly — an audit that flags everything flags nothing. Lead with what actually
  matters: security/secrets, EOL deps in use, missing tests on core logic.
- Brevity is a feature. Cut any section that would be empty. A short report that gets read beats a
  thorough one that doesn't.
