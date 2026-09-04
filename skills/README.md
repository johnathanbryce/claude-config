# Skills — legend

Reference for humans. Claude discovers skills by looking for subdirectories that contain a
`SKILL.md`, so this file is inert — it is not a skill and is not loaded into context.

## The skills

| Skill | Does | Writes files? | Arguments |
|---|---|---|---|
| `/spec` | Rough idea → one-page spec: problem, goals/non-goals, numbered requirements, interface sketch, edge cases, open questions. | No — chat only | `[rough feature idea]` |
| `/scaffold` | Mechanical structure only: files, dirs, imports, markup, config. All logic lands as `TODO(John)` stubs. | Yes | `[light\|medium\|heavy] what to scaffold` |
| `/unit-tests` | Tests for uncommitted changes, in whatever language and runner the repo already uses. Runs them to green by default. | Yes | `[language] [scaffold]` |
| `/diff-review` | Reviews working-tree changes against my standards. Correctness outranks everything. Reports only — never edits. | No | `[optional path to scope]` |
| `/docs` | Feature doc in `docs/` from the branch diff, or a PR description. | Yes | `[pending] [pr]` |
| `/explain` | End-of-build report: what was built and why, ranked by importance. Report, not a review. | No — chat only | — |
| `/diagram` | Image or description → Mermaid in markdown. Inserts into a named `.md` or outputs to chat. | Yes (edits target `.md`) | `[description and/or target .md — or attach an image]` |
| `/onboard` | New codebase → setup runbook *I* run, ranked reading order, domain glossary, who-to-ask map, ship process, plus a full health + dependency audit. **Strictly read-only — never installs, builds, or starts anything.** | Yes — to `~/onboarding/<repo>/` | `[path] [quick] [no-deps]` |

## The intended order

The five core skills chain across the life of a feature:

```
/spec  →  /scaffold  →  [John writes the logic]  →  /unit-tests  →  /diff-review  →  /docs
```

1. **`/spec`** before code exists. Its output is what `/scaffold` reads if no description is passed.
2. **`/scaffold`** builds the skeleton. It deliberately stops at the logic — that gap is mine to fill.
3. **`/unit-tests`** and **`/diff-review`** both read uncommitted work, so they run *after* the logic
   is written and *before* the commit. Tests first: `/diff-review` is more useful when the tests
   already encode the intended behavior.
4. **`/docs`** runs on finished work. `/docs pr` at PR time; bare `/docs` for a feature doc.

**Not in the chain:**

- **`/explain`** — end of an AI-driven build, when I need orienting in a result I didn't write
  line by line. Deliberately separate from `/diff-review`: `/explain` reports, `/diff-review` judges.
- **`/diagram`** — standalone, any time a concept needs to live in `.md` notes.
- **`/onboard`** — day one on a codebase I did not write. Superset of `/audit`: it does the health pass
  *and* the orientation half `/audit` has no opinion about (setup runbook, glossary, ownership, reading
  order, questions to ask). Run it once when I join; run `/audit` later for a pure health re-check.
  **It never executes anything** — its `allowed-tools` grants only read-only commands, so the setup
  steps come back as a checklist I run myself. `/audit` still carries a general `Bash` grant.

## Distinctions worth remembering

- **`/explain` vs `/diff-review`** — `/explain` tells me what changed and why. `/diff-review` tells me
  what's wrong with it. Neither does the other's job, by design.
- **`/diff-review` vs `deep-code-review`** — `/diff-review` is the fast pre-commit gate. The
  `deep-code-review` *agent* (in `../agents/`) is the heavy multi-pass tier for PR / pre-merge on
  risky changes. Not a skill; invoked as an agent.
- **`/onboard` vs `/audit`** — `/audit` asks "what is wrong with this codebase." `/onboard` asks "what
  do I need to understand, and who do I ask." `/onboard` contains the audit; `/audit` does not contain
  the orientation. On a repo I just joined, `/onboard` is the one to reach for.
- **`/scaffold` never writes logic** — control flow, queries, transformations. That is the whole point
  of the skill, not a limitation to work around.
- **`scaffold` as an argument to `/unit-tests`** means the same thing it means in `/scaffold`: named
  stubs for me to fill in, plus exactly one implemented case per file as a pattern anchor.
