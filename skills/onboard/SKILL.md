---
description: Onboard onto a codebase you just joined — a one-page brief that leads with what the repo is, the most important files to read first, how to run it, and who to ask what. STRICTLY READ-ONLY — never installs, builds, or starts anything. No subagents unless `deps` is passed. Use on day one at a new job, when inheriting a repo, or before contributing to an unfamiliar project. Also the health re-check on a repo you already know. Distinct from /init (documents structure, judges nothing).
argument-hint: "[path to repo — defaults to cwd] [deps to add the dependency sweep — spawns a subagent, costs real money on pay-per-token]"
allowed-tools: Read, Grep, Glob, Write, Edit, WebSearch, WebFetch, Bash(git log:*), Bash(git shortlog:*), Bash(git branch:*), Bash(git ls-files:*), Bash(git status:*), Bash(git rev-parse:*), Bash(git show:*), Bash(git remote:*), Bash(git check-ignore:*), Bash(git rev-list:*), Bash(ls:*), Bash(find:*), Bash(cat:*), Bash(head:*), Bash(tail:*), Bash(wc:*), Bash(rg:*), Bash(grep:*), Bash(sed -n:*), Bash(node -v), Bash(npm -v), Bash(python3 -V)
---

Onboard John onto this codebase: $ARGUMENTS

Default target is the current directory.

## Cost contract — read first

**No subagents. Ever, unless `deps` is in `$ARGUMENTS`.** Run every pass inline, yourself.
A previous version of this skill fanned out to subagents and cost $24 on a pay-per-token
account for one repo. `Task` is deliberately absent from `allowed-tools` so any spawn
prompts John first — if that prompt appears without `deps`, the answer is no.

**Reading budget: ~40 files, ~2,500 lines total.** Read manifests, config, entry points, and
the exemplars. Skim everything else with `head -40` or grep. When the budget is spent, stop
reading and write; mark what you did not read as _(not read)_. A monorepo does not raise
the budget — it makes prioritisation the job.

| Argument | Effect                                                                                                                                                                                                      |
| -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| _(none)_ | Orientation + light health pass. No subagents.                                                                                                                                                              |
| `deps`   | Also spawn the `deps-auditor` subagent, scoped to the live project. **Warn once in chat before spawning: "this spawns a subagent — on pay-per-token this costs real money, continue?" and wait for a yes.** |

## No-execution contract

**Never run the project.** No install, build, dev server, test suite, project script,
package-manager command, migration, seed, or Docker. `npm install` runs postinstall scripts
from a repo nobody has read yet. John runs every command himself, from the runbook.
Only `node -v`, `npm -v`, `python3 -V` may execute, to record local runtimes.
If `deps` spawns a subagent, its prompt must carry this contract verbatim:

> READ-ONLY. Do NOT install, build, test, start a server, or run any project or
> package-manager command (`npm audit`, `npm ls`, `tsc`, `pip`, …). Work from manifests
> and web research. If something needs execution to determine, report it as undetermined
> and name the command.

## Framing

John has zero context and no political capital. Output is **what to understand, in what
order** and **what to ask, and whom** — not a fix list. Health findings are awareness
("known-shaped landmine"), not tickets.

Label confidence: default is verified (you opened the file). Mark _(inferred)_ when
pattern-matched. Every **unknown** becomes a question in the brief. Never guess what a
repo "probably" does.

## Passes — all inline, in this order

1. **Shape.** Find every manifest (`package.json`, `pyproject.toml`, `go.mod`, `Gemfile`,
   `docker-compose.yml`, `Dockerfile`). One → simple. Several → rank by 90-day churn and
   what the README points at; **only the live one gets a runbook**, the rest get one table
   row each. Say plainly if the repo is not one app.
2. **Run path.** Read in this authority order: `README`, `CONTRIBUTING`, compose, `Makefile`,
   manifest scripts, version files (`.nvmrc`, `.tool-versions`), **CI workflows (the
   most honest source)**, `.env.example`. Produce an exact ordered command list split into
   _runnable now_ and _blocked on a human/credential_ (name the missing env var, masked
   prefix only, never a value). Read any script whose name does not say what it does and
   state what it invokes. The runbook is **derived, not verified** — say so.
3. **Git.** Check for a bulk rename first (`git log --diff-filter=R --name-status -20`);
   if one commit moved most of the tree, name it and stop trusting path recency. Then
   `git shortlog -sne --since=1.year` (overall and per top-level dir), 90-day churn by
   file, `git log --oneline -40` for commit style, `git branch -r --sort=-committerdate | head`.
   Reconcile one human under several emails. Solo repo → no ownership map; report _what
   the history does not record_ instead.
4. **Map + glossary.** Stack, shape, entry points, where real logic lives. Extract domain
   nouns from types, models, tables, routes, enums — one line each. A noun you cannot
   define is a question. Web-search framework conventions you are not sure of; do not
   teach them from memory.
5. **House style.** Two or three recent, non-trivial exemplar files by a core committer:
   the canonical component, handler, and test. One line each on the pattern. Note lint,
   type strictness, test naming, and any convention drift.
6. **Health, light.** Count `TODO|FIXME|HACK|XXX`; surface at most five with `file:line`.
   Tests: framework, rough coverage signal, whether CI enforces them. Secrets: committed
   `.env` or keys in source (check `git log --all` for history leaks). Duplicate
   implementations of the same thing (two HTTP clients) → unfinished migration → question.
7. **Deps** — only with `deps`. Spawn `deps-auditor` scoped to the live project, then grep
   the codebase yourself for every deprecated API it names; report only the ones actually
   called, with `file:line`.

## Reading order — ranked by evidence

Score files on: entry point, 90-day churn, import centrality
(`rg -o "from ['\"](\.\.?[^'\"]+)" -N -I | sort | uniq -c | sort -rn | head -30`, adapt per
language), domain density, and config that governs everything. Cut to **5–8 files**.

## Output — one file, one page

Write **`~/onboarding/<repo-name>/ONBOARDING.md`**, outside the target repo. Update in
place on a re-run, never a `-v2`. Header line: generated date + commit SHA.

**Hard cap: 120 lines.** Lead with what matters most. It is a brief, not a report. If a
section has nothing to say, omit it — no "there is no CI" paragraphs. Tables over prose.
No exhaustive inventories, no appendix. Whatever does not fit gets cut, not compressed.

Sections, in this order, with rough line budgets:

1. **What this is** — 3 sentences: what the app does, stack, shape. Plus the single first
   thing to do. _(≤6 lines)_
2. **Read these first** — the ranked 5–8 files, one line each on what it teaches. _(≤10)_
3. **Get it running** — runnable steps as a copy-paste block, then blocked steps as a table
   `step | blocker | who unblocks`. One-line note that nothing was executed. _(≤25)_
4. **Ask** — questions grouped by person, each with _why it matters_ in the same line.
   Lead with contradictions (doc vs doc, doc vs tree). Specific enough to answer in two
   sentences. Solo repo → retitle "what the repo does not record". _(≤15)_
5. **Map** — entry points, key dirs, hot vs cold. Table. _(≤15)_
6. **Glossary** — domain nouns only, one line each. _(≤12)_
7. **Ship** — branch naming, commit style, required checks. End with _your first PR must
   pass X, Y, Z._ _(≤8)_
8. **Style** — the exemplar files, one line each. _(≤5)_
9. **Watch out** — ranked health findings, secrets first, max five. Deps only with `deps`. _(≤10)_
10. **Not determined** — what you could not verify and the command or person that would. _(≤6)_

### In chat, afterward

One line confirming nothing was executed and no subagent ran (or that one ran, if `deps`),
the file path, and **five lines**: what the app is, can the env come up unassisted (if not,
on what), top two questions for tomorrow, biggest single risk. Do not paste the file.

## Rules

- Read before you assert. Every claim traces to a file you opened or a command you ran.
- Prioritise ruthlessly. Flagging everything flags nothing.
- Never echo secret values.
- Execute nothing. Spawn nothing without `deps` and a yes.
- Never commit, branch, or modify a file in the target repo. Only `~/onboarding/` is written.
