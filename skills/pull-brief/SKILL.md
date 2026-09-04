---
description: Brief me on what changed in a shared repo since I last looked — filtered to other people's commits, with deterministic flags for installs, migrations, env and config changes I need to act on. Use when I ask what changed, what I missed, what landed while I was away, or after a git pull on a team repo. Also manages which repos the automatic SessionStart briefing is enabled for.
argument-hint: "[optional: a git rev to compare from, or 'on' | 'off' | 'status']"
allowed-tools: Bash(~/.claude/hooks/pull-brief.sh:*), Bash(git log:*), Bash(git diff:*), Bash(git show:*), Bash(git status:*), Read, Grep, Glob
---

Brief John on what changed in this repo since he last looked.

The heavy lifting is already done by `~/.claude/hooks/pull-brief.sh`, which is the
same engine the automatic SessionStart briefing uses. Your job is to run it and
turn its facts into a short, ranked, human briefing — not to re-derive them.

## Dispatch on $ARGUMENTS

| $ARGUMENTS | Do this |
|---|---|
| empty | `~/.claude/hooks/pull-brief.sh report` — briefs from the last recorded baseline (or the last 7 days if there is none) |
| a git rev (`HEAD~10`, a SHA, `origin/main`, a tag) | `~/.claude/hooks/pull-brief.sh report <rev>` |
| `on` / `off` / `status` | run that subcommand and report the result — nothing else |

`report` deliberately does **not** advance the baseline, so running it twice is safe
and idempotent.

## Writing the briefing

Rank by what forces John to *do* something, then by what he must *know*.

1. **Action required — lead with this.** Everything under `ACTION REQUIRED` in the
   script output is a file-pattern match, not an inference, so state it as fact.
   Then add the value you can that the grep cannot: read the actual manifest diff and
   name the concrete command. `Gemfile.lock` moved → `bundle install`;
   `db/migrate/` gained files → `bin/rails db:migrate` (and say which tables/columns
   the migration touches — Read the migration file); `.env.example` moved → diff it
   against his real `.env` if one exists and name the *specific* new keys.
   If `ACTION REQUIRED` is empty, say so in one line and move on.
2. **Must-know changes by other people.** Group the foreign commits by theme, not by
   commit. Three commits titled "wip", "fix", "update" that together rewrote the auth
   middleware are one item: "auth middleware rewritten". Read the diffs where the
   commit messages are too thin to classify — thin messages are the norm, not the
   exception.
3. **Breaking changes to anything he touches.** Renamed/deleted exported functions,
   changed function signatures, changed API response shapes, moved files, renamed env
   vars, changed DB columns. These are what silently break his working tree. Call them
   out even if small.
4. **His own commits, critical items only.** When the range contains his own work
   (a squash-merged PR coming back down), do not summarize it — he wrote it. Mention
   it only if it arrived *changed*: squashed differently, amended, conflict-resolved
   by someone else, or partially reverted. Otherwise one line: "your PR #N landed as
   <sha>, unchanged."

## Rules

- **Be short.** The default is under 15 lines. This is a standup update, not a report.
  Expand only when there is genuinely a lot, or when John asks for depth.
- **Never invent an action.** If you are not sure a change needs a reinstall or a
  migration, say what changed and let John decide. A briefing that cries wolf gets
  ignored, which defeats the whole thing.
- **Read the code when the commit message is useless.** "buncha updates" tells John
  nothing; the diff tells him everything.
- **Flag project-invariant violations you happen to see.** For repos with a
  `CLAUDE.md` review checklist (cababble has one), if an incoming commit trips it,
  that is a must-know item — but do not turn this into a full code review. Point at
  it and offer `/diff-review` or `/code-review` for depth.
- If `CLAUDE.md` / `AGENTS.md` itself changed, read the diff and tell him what the
  new instruction is. That one matters more than it looks — it changes how every
  future AI-assisted change in the repo behaves.

## Enable / disable

Automatic briefings only fire in repos on the allowlist
(`~/.claude/pull-brief/repos.txt`). Everything else is silent — that is deliberate,
since solo repos have nothing to brief. `on` adds the current repo and baselines it at
current `HEAD` so John is not briefed on pre-existing history. `off` removes it.
Extra git identities that count as "John" live in `~/.claude/pull-brief/identities.txt`
— add the work GitHub noreply address there when he gets the AlgaeCal repo, or every
one of his own commits will read as somebody else's.
