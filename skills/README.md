# Skills — legend

Reference for humans. Claude discovers skills by looking for subdirectories that contain a
`SKILL.md`, so this file is inert — it is not a skill and is not loaded into context.

## The skills

| Skill | Does | Writes files? | Arguments |
|---|---|---|---|
| `/spec` | Rough idea → one-page spec: problem, goals/non-goals, numbered requirements, interface sketch, edge cases, open questions. | Yes — `<slug>-spec.md` in a gitignored `.local/` if present, else repo root (flagged delete-before-push) | `[rough feature idea]` |
| `/scaffold` | Mechanical structure only: files, dirs, imports, markup, config. All logic lands as `TODO(John)` stubs. Reads the `/spec` file; never writes tests. | Yes | `[light\|medium\|heavy] [spec.md] [description]` |
| `/unit-tests` | Tests for uncommitted changes, in whatever language and runner the repo already uses. Runs them to green by default. | Yes | `[language] [scaffold]` |
| `/docs` | Feature doc in `docs/` from the branch diff. | Yes | `[pending]` |
| `/pr-description` | PR title + body for the branch. Follows the repo's own PR template when there is one; offers to open the PR with `gh`. Never pushes. | Only a scratch body file | `[base branch] [draft] [nocreate]` |
| `/explain` | End-of-build report: what was built and why, ranked by importance. Report, not a review. | No — chat only | — |
| `/architect` | Mermaid tech/infra flowchart + key flows + gaps, as `.md` rendered to SVG/PNG. `pre` = proposed architecture from a spec; `post` = as-built from the branch. | Yes | `pre\|post [spec.md]` |
| `/diagram` | Image or description → Mermaid in markdown. Faithful transcription, no judgment. | Yes (edits target `.md`) | `[description and/or target .md — or attach an image]` |
| `/pull-brief` | What changed in a shared repo since I last looked, filtered to other people's commits, with flags for installs/migrations/env/config. Also runs automatically at SessionStart for allowlisted repos. | No | `[on\|off]` |
| `/onboard` | New codebase → one-page brief: what it is, 5–8 files to read first, runbook *I* run, who to ask what. **Read-only. No subagents unless `deps`.** Also the health re-check on a known repo. | Yes — `~/onboarding/<repo>/ONBOARDING.md` | `[path] [deps]` |

## Cost warning

`/onboard deps` spawns a subagent. Fine on a Max plan. On a pay-per-token account one
run has cost $24–$88. Leave `deps` off there.

## The intended order

```
/spec  →  /scaffold  →  [John writes the logic]  →  /unit-tests  →  /code-review  →  /docs  →  /pr-description
```

1. **`/spec`** before code exists. Pass the file to `/scaffold` or `/architect pre`.
2. **`/scaffold`** builds the skeleton and stops at the logic — that gap is mine.
3. **`/unit-tests`** then the built-in **`/code-review`** on uncommitted work, before commit.
4. **`/docs`** on finished work.
5. **`/pr-description`** last. Never pushes.

**Not in the chain:** `/explain` (orient in an AI-built result), `/diagram` and `/architect`
(standalone artifacts), `/pull-brief` (mostly automatic), `/onboard` (day one on a repo, or a
health re-check later).

## Distinctions worth remembering

- **`/explain` vs `/code-review`** — explain tells me what changed and why; code-review tells me what's wrong with it.
- **`/code-review` vs `deep-code-review`** — built-in `/code-review` is the fast pre-commit gate. The `deep-code-review` *agent* (`../agents/`) is the heavy multi-pass tier for risky PRs.
- **`/diagram` vs `/architect`** — diagram transcribes a source I give it; architect reasons about the system and makes judgment calls it flags.
- **`/scaffold` never writes logic.** That is the point, not a limitation.
