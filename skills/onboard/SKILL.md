---
description: Onboard onto a codebase you just joined — produces a setup runbook you run yourself, a ranked reading order, a domain glossary, an ownership map of who to ask what, the ship process, and a full health/dependency audit. Use on day one at a new job, when inheriting a repo, or before contributing to an unfamiliar open-source project. STRICTLY READ-ONLY — it never installs, builds, or starts anything. Distinct from /audit (health only, no orientation) and /init (documents structure, judges nothing).
argument-hint: "[path to repo — defaults to cwd] [quick to skip deep passes] [no-deps]"
allowed-tools: Read, Grep, Glob, Task, Write, Edit, WebSearch, WebFetch, Bash(git log:*), Bash(git shortlog:*), Bash(git branch:*), Bash(git ls-files:*), Bash(git status:*), Bash(git rev-parse:*), Bash(git show:*), Bash(git remote:*), Bash(git check-ignore:*), Bash(git rev-list:*), Bash(ls:*), Bash(find:*), Bash(cat:*), Bash(head:*), Bash(tail:*), Bash(wc:*), Bash(rg:*), Bash(grep:*), Bash(sed -n:*), Bash(node -v), Bash(npm -v), Bash(python3 -V)
---

Onboard John onto this codebase: $ARGUMENTS

Default target is the current directory.

## The no-execution contract

**This skill NEVER runs the project.** No install, no build, no dev server, no test suite, no project
script, no package-manager command, no migration, no seed, no Docker. Not as a convenience, not to
"verify" a step, not because a command looks harmless. **John runs every command himself.**

The reason is not caution in the abstract. `npm install` executes arbitrary postinstall scripts from a
repo you have not read yet, and `npm run <anything>` executes whatever that repo defines. On a codebase
joined this week, nobody knows what those do yet. Listing a command is free; running it is not.

This is enforced in two places, and you must respect both:

1. **`allowed-tools` above enumerates read-only commands only.** There is no general `Bash` grant. If
   you want a command that is not on that list, that is the guardrail working — write the command into
   the runbook for John instead of reaching for it.
2. **The instruction here**, which also binds every subagent you spawn (see the fan-out note below).

**The one carve-out, stated plainly so the guarantee is precise:** `node -v`, `npm -v`, and `python3 -V`
are permitted, purely to record which runtimes are on the machine. They read a version string and cannot
alter anything. Nothing else executes. If you need another command's output, say in the report that it
was not verified, and name the command that would have answered it.

| Argument | Effect |
|---|---|
| *(none)* | Full pass: orientation + health + dependencies. |
| `quick` | Skip the health/deps passes. Orientation only — when you need to be productive today and will audit later. |
| `no-deps` | Everything except the dependency-currency sweep (offline, or private registries). |

## Framing — read this before anything else

You are orienting someone with **zero context and no political capital.** They joined this week. They
cannot yet tell which mess is a known mess, and they have no standing to file twenty debt tickets.

That changes what a finding is *for*. You are not producing a fix list. You are producing:

1. **What do I need to understand, and in what order**
2. **What do I need to ask a human, and which human**

Every health finding is framed as *awareness* — "this is a known-shaped landmine, don't be surprised" —
not as a task. If something genuinely must be fixed, say so once, plainly, and note that raising it is a
week-three move, not a week-one move.

**Label your confidence on every non-trivial claim:**

- **verified** — you opened the file or ran the command. No qualifier needed; this is the default.
- **inferred** — pattern-matched from naming, structure, or convention. Mark it: *(inferred)*.
- **unknown** — you could not determine it. **Every unknown becomes a question in section 3, assigned
  to a named person.** An unknown you silently drop is the worst output this skill can produce.

Never narrate what a repo "probably" does. "I could not determine X, ask Y" is a better line than a
confident guess, and it is the whole reason section 3 exists.

## Passes — run 1–5 in parallel via the Task tool, then synthesize

These passes are independent. Fan them out concurrently as subagents and merge the results. On a small
repo (< ~100 files) doing them inline is fine; on a monorepo, parallelize or this takes forever.

**⚠️ The no-execution contract binds subagents, and you must restate it in every prompt.** A subagent
inherits none of this file, and its own definition may grant it unrestricted `Bash`. Every spawned
agent's prompt must carry an explicit line to the effect of:

> *READ-ONLY. Read files, grep, and use read-only git and web research only. Do NOT install, build, run
> a test suite, start a server, or execute any project script — including `npm audit`, `npm ls`,
> `tsc`, `pip`, or any package-manager command. If you cannot determine something without executing,
> report it as undetermined and name the command that would have answered it.*

Without that line a subagent will run `npm audit` or `tsc -b` on its own initiative and the guarantee
given to the user is false. **The guarantee is only as strong as its weakest delegate.** If a subagent
reports having executed something anyway, say so in the report — see the Rules.

### Pass 1 — The run path

The highest-value output of this entire skill. Get from clone to running app with no guessing.

**First, establish how many apps there actually are.** Search the whole tree for manifests
(`package.json`, `requirements.txt`, `pyproject.toml`, `go.mod`, `Gemfile`, `docker-compose.yml`,
`Dockerfile`). A repo with one is simple. A repo with several is a monorepo, a portfolio of independent
projects, or a mix — and **which one it is changes the whole report.**

When there is more than one, **do not write a runbook for each.** Rank them:

1. **The live one** — identified by 90-day churn, by what the repo's own docs point at, and by whether
   it is under an `archive`/`old`/`deprecated` path. This is the only one that gets the full, exact,
   verified runbook.
2. **Everything else** — a single table: path, stack, one line on what it is, and any blocker obvious
   from its manifest. No step-by-step.

Say plainly in the TL;DR when a repo is **not one app**. Getting that wrong makes every later section
wrong, because "how to run it" and "read these first" both assume a single thing to run and read.
If there is genuinely no root-level app at all, say *that* in one line rather than inventing a
root runbook that does not exist.

Then, for the live project, read in this order of authority: `README`, `CONTRIBUTING`, `docker-compose.yml`, `Makefile`,
`package.json` scripts, `pyproject.toml` / `Gemfile` / `go.mod`, `.nvmrc` / `.node-version` /
`.tool-versions`, CI workflow files (**CI is the most honest source — it is the setup that provably
works**), and any `.env.example`.

Produce an **ordered, exact command list**, then split every step into two buckets:

- **You can run this now** — no external dependency.
- **Blocked on a human or a credential** — an env var only someone can hand you, a VPN, a private
  registry token, a seeded database, an account on a third-party service, repo permissions.

For the blocked bucket, diff `.env.example` against any real `.env` and name **specific missing keys**.
Never print a secret's value — name the variable and a masked prefix only (`SHOPIFY_API_KEY=shpat_…`).

**The blocked bucket IS the environment half of section 3.** Every blocked step becomes a question with
a named owner. Do not let a blocker exist only in section 2.

Also capture: required runtime versions, required services (Postgres, Redis, a local proxy), ports used,
and how you *know the app is up* — the URL to hit and what a healthy response looks like.

**Write the runbook as a checklist John executes, in order, in his own terminal.** Exact commands,
copy-pasteable, no placeholders he has to guess at.

Where a step's behavior is not obvious — an unfamiliar postinstall, a script whose name does not say
what it does — **read the script and say what it will do.** Explaining what `npm run setup` actually
invokes is the highest-value thing in this section and costs nothing.

State clearly that the runbook is **derived, not verified**: assembled from manifests and CI config,
never watched working. That distinction belongs in the report, not just in your head.

### Pass 2 — Git archaeology

Facts about the humans and the momentum, derived rather than guessed.

**Before trusting any of this, check for a bulk rename.** A restructure, a monorepo migration, or a
mass `git mv` rewrites the last-touched date of every path it moved, and after one, `git log -1 -- <path>`
returns the rename date for *everything*. Recency becomes worthless and churn output mixes old and new
path names in the same list.

```
git log --diff-filter=R --name-status -20        # were paths renamed, and when
git log --since=90.days --pretty='%h %ad %s' --shortstat | head -40   # spot the outlier commit
```

If one commit touches a large fraction of the tree, **say so in the report, name the commit, and stop
using directory recency as a signal.** Fall back to: churn counts computed with `--follow` where it
matters, the repo's own hand-maintained status docs if any exist, and per-file history rather than
per-directory. Reporting a stale-looking directory that was actually just moved is a confident wrong
answer of exactly the kind section 3 exists to prevent.

```
git shortlog -sne --since=1.year                        # who works here at all
git shortlog -sne --since=1.year -- <each top-level dir> # who owns what
git log --since=90.days --name-only --pretty=format: | sort | uniq -c | sort -rn | head -40
git log --oneline -60                                    # commit message convention
git branch -r --sort=-committerdate | head -30           # branch naming convention
git log --since=90.days --pretty='%an %s' | head -60     # what the team is actually working on
```

Also read `CODEOWNERS` if it exists — it beats inference, but cross-check it against shortlog, because
CODEOWNERS files go stale and shortlog does not.

Produce:

- **Ownership map** — directory → most likely person to ask, with commit counts as the evidence.
- **Hot / cold map** — directories with heavy 90-day churn vs. directories nobody has touched in a
  year. Hot is where you will be assigned. Cold is either stable or abandoned, and *which one* is a
  question for section 3.
- **Conventions** — branch naming, commit message style, whether they squash, whether messages are
  useful or all say "fix".

**If the repo has one real author, the ownership map is degenerate — say so and invert the pass.**
(Watch for the same human under several identities: a work address, a personal address, and a
`users.noreply.github.com` web-editor address are one person, not three. Reconcile before concluding.)
A solo repo, a fresh repo, or an inherited repo whose authors have all left produces no one to ask. Do
not pad the section with "ask whoever owns X" — it produces nothing. Instead, spend the pass on **what
the history does not explain**: decisions with no recorded rationale, work that stops mid-stream,
directories whose purpose is not derivable. Those become section 3, which stops being *who to ask* and
becomes **what the repo does not record.** That is a genuinely useful artifact — it just is not an
ownership map, and it should not be dressed up as one.

### Pass 3 — Map and glossary

**Map:** what the app does, its stack, its shape (monolith / service / monorepo / library), its entry
points, and where real logic lives vs. generated, vendored, or config noise. Architecture in prose.

**Glossary — do not skip this, it is the pass that makes the code readable.** Unfamiliar architecture is
rarely what slows a new hire down. Unfamiliar *nouns* are. Extract the recurring domain vocabulary from:
type and interface names, model/entity classes, database table and column names, GraphQL types, route
segments, enum values, and directory names.

Separate **domain terms** (mean something to the business) from **framework terms** (mean something to
the stack). Define each domain term in one line, from usage you actually read. A domain term you cannot
define is a **question for section 3** — those are usually the most valuable questions in the report,
because they are the words everyone will use in standup and assume you know.

**If the stack has framework conventions you are not certain of** — a routing file convention, a data
loading pattern, a build pipeline — **web-search the current official docs.** Do not teach it from
memory; these change, and being confidently wrong about the house framework on day one is expensive.

### Pass 4 — House style

Find the **exemplars**: two or three files that best represent how things are done here. Typically the
canonical UI component, the canonical API route or handler, and the canonical test. Pick ones that are
recent, non-trivial, and written by a core committer — not the oldest file in the repo.

For each, say in one line what pattern it demonstrates. The instruction to John is literally *"copy the
shape of these"* — his first PR should be indistinguishable from the surrounding code.

Also note: formatting/lint setup, module style, type strictness, test framework and how tests are named,
and any convention drift that means there is **no** single house style (itself a useful finding).

### Pass 5 — Health, debt, and dependencies

Unless `quick` was passed:

- **Landmines:** grep `TODO|FIXME|HACK|XXX|@deprecated`. Count them; surface the notable ones with
  `file:line`. A TODO from three years ago in a hot directory is a finding; one in a cold directory is
  a footnote.
- **Tests:** do they exist, what framework, roughly how much real surface they cover. Signal, not a
  coverage number. Whether CI actually enforces them matters more than whether they exist.
- **Secrets and config:** committed `.env`, hardcoded keys, credentials in source. Check `git log --all`
  to distinguish a real history leak (serious, and a same-day conversation with whoever owns security)
  from a gitignored local `.env` (expected). **Never echo a secret's value** — variable name and masked
  prefix only, in chat and in the file.
- **Rot:** large commented-out blocks, dead code, duplicated logic, competing implementations of the
  same thing (two HTTP clients, two date libraries) — those signal an unfinished migration, which is
  always worth a question.

Unless `no-deps` was passed, spawn the **`deps-auditor`** subagent pointed at this repo — **scoped to
the live project identified in Pass 1**, not the whole tree, when the repo holds several. Auditing
archived or parked projects is noise, and the skill's own prioritization rule applies to itself. Say in
the report what you scoped it to and why. **Carry the read-only directive into its prompt verbatim** (see
the fan-out note above), and tell it explicitly to work from the manifests plus live registry and web
research — **not** from `npm audit`, `npm ls`, `pip list`, or any other executed command. Left unsaid,
it will run them on its own initiative. When it
returns, **take the deprecated APIs it named and grep the codebase yourself.** A deprecated method the
repo never calls is a footnote; one used at `file:line` is a real finding. That usage check is yours, not
the subagent's. If it returns nothing usable, note that and move on — never block the audit on it.

## Synthesis — ranking the reading order

Section 4 of the report is a ranked reading list, and it must be ranked by **evidence, not vibes.**
Score candidate files on:

1. **Entry points** — the file that boots the app is always first.
2. **Churn** — high 90-day commit count means it is alive and you will touch it.
3. **Centrality** — how many other files import it. Approximate cheaply, e.g.
   `rg -o "from ['\"](\.\.?[^'\"]+)" -N -I | sort | uniq -c | sort -rn | head -30` (adapt to the
   language). A file everything imports is load-bearing.
4. **Domain density** — files defining core models/types teach the vocabulary fastest.
5. **Config that governs everything** — the router, the schema, the build config.

Then cut to **5–8 files, in reading order**, each with one line on *what reading it teaches you.* A
twenty-file list is a list nobody reads. If two files teach the same thing, keep the better-written one.

## Output

Write to **`~/onboarding/<repo-name>/`** — outside the target repo, always. Two files:

- **`ONBOARDING.md`** — the primary artifact. Tight enough to read start to finish in one sitting.
- **`appendix.md`** — the exhaustive reference: full dependency table, full TODO inventory, full
  ownership tables, per-directory churn numbers. Written to be grepped, not read.

Update both in place on a re-run. Never create a parallel `-v2`. Note at the top of `ONBOARDING.md` the
date it was generated and the commit SHA it was generated against, so staleness is visible later.

### `ONBOARDING.md` sections, in this order

The order is deliberate and is **not** the order of an audit report. It is ranked by what is needed
first on day one.

1. **TL;DR** — what this app is in three sentences, and the single first thing to do.
2. **Get it running** — the ordered runbook **for John to execute himself.** Runnable steps first, then
   blocked steps with who unblocks each. Head the section with a one-line note that nothing was
   executed, so the difference between *documented command* and *proven to work* stays visible.
3. **Questions, grouped by person** — the artifact to bring to standup. Every question carries *why it
   matters* and *what you would do with the answer*. Assign each to a named person from the ownership
   map (or "whoever owns X" if the name is genuinely unknown). Sources: every blocked setup step, every
   undefined domain term, every unknown from any pass, every cold-directory ambiguity, every apparent
   half-finished migration. **A question like "ask about the architecture" is a failure** — it must be
   specific enough that the person can answer it in two sentences.
   **Lead with contradictions.** Two documents that disagree, or a doc that disagrees with the working
   tree, outrank everything else here — they are the findings a newcomer is uniquely positioned to
   notice and that nobody inside the repo will spot again.
   **On a solo or abandoned repo** (see Pass 2) this section becomes *what the repo does not record*,
   addressed to whoever inherits it. Retitle it honestly rather than inventing owners.
4. **Read these first** — the ranked 5–8, in order, each with what it teaches.
5. **The map** — architecture prose, entry points, key directories, hot vs. cold.
6. **Glossary** — the domain nouns, one line each.
7. **How to ship** — branch naming, commit style, PR template, required CI checks, how deploys happen.
   End with a literal line: *your first PR must pass X, Y, Z.*
8. **House style** — the exemplar files and what each demonstrates.
9. **Health and debt** — ranked, framed as awareness. Security and secrets first.
10. **Dependency risks** — criticals, plus which deprecated APIs are actually used at `file:line`.
11. **Confidence and unknowns** — what you could not determine and why. Cross-reference section 3.

### In chat, afterward

A one-line confirmation that nothing was executed, both file paths, and a **six-line summary**: what the app is, whether the environment
can be brought up unassisted or is blocked (and on what), the top three questions to ask tomorrow, and
the single biggest health risk. Do not paste the report into chat — it is in the file.

## Rules

- **Read before you assert.** Every claim traces to a file you opened or a command you ran.
- **Prioritize ruthlessly.** A report that flags everything flags nothing.
- **Cut empty sections.** If there is no CI, say "no CI" in one line rather than writing a section
  about its absence.
- **Never echo secret values**, in chat or in either file.
- **Execute nothing.** See the no-execution contract at the top. There is no mode of this skill that
  installs, builds, starts, or tests anything. If a step needs running, it goes in the runbook for John.
- **The contract binds subagents too.** Restate it in every subagent prompt. If a subagent reports
  having run something anyway, **say so in the report** rather than letting the read-only claim stand
  unqualified — an overstated guarantee is worse than a stated exception.
- Do not commit anything, do not create branches, do not modify a single file in the target repo. The
  only files this skill writes live under `~/onboarding/`.
