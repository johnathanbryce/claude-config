# claude-config

Backup of my [Claude Code](https://claude.com/claude-code) user configuration — the contents of `~/.claude`.

This repo exists so a new Mac gets my full setup back with a clone, and so my
hand-written notes are not one disk failure away from gone.

**This repo is private and must stay that way.** It contains project memory notes
that reference production infrastructure, plus personal career material.

## What's in here

| Path | What it is |
|---|---|
| `settings.json` | Permissions allowlist, model, hooks, effort level |
| `skills/` | Custom slash-command skills (`/spec`, `/audit`, `/diff-review`, `/architect`, …) |
| `agents/` | Custom subagent definitions (`deep-code-review`, `deps-auditor`) |
| `hooks/` | Shell hooks — `pull-brief.sh` (SessionStart briefing), `secrets-guard.sh` |
| `pull-brief/` | Allowlist + author identities for the pull-brief hook |
| `projects/*/memory/` | **Hand-written memory notes per project.** The reason this repo exists |

## What's deliberately not in here

Everything Claude Code regenerates on its own, or that means nothing on another
machine: `sessions/`, `shell-snapshots/`, `file-history/`, `session-env/`, `ide/`,
`debug/`, `telemetry/`, `backups/`, `plugins/`, `stats-cache.json`,
`mcp-needs-auth-cache.json`, `*.bak-*`, and `pull-brief/state/`.

`projects/` is excluded wholesale — those are session transcripts, ~17MB and
growing — **except** `projects/*/memory/`, which is tracked. See `.gitignore`;
the rule re-admits directories one level at a time, because git cannot
re-include a path whose parent directory is excluded.

## Restore on a new Mac

Install Claude Code first — it creates a default `~/.claude`, which the reset
below overwrites with the tracked files.

```bash
mkdir -p ~/.claude && cd ~/.claude
git init -b main
git remote add origin https://github.com/johnathanbryce/claude-config.git
git fetch origin
git reset --hard origin/main
git branch --set-upstream-to=origin/main main
```

Executable bits on `hooks/*.sh` are stored in git, so no `chmod` is needed.

### Then, two machine-specific fixes

**1. If the new Mac's username is not `johnbryce`,** the SessionStart hook path in
`settings.json` is absolute and will silently fail. Fix it:

```bash
cd ~/.claude
sed -i '' "s|/Users/johnbryce/.claude/hooks/|$HOME/.claude/hooks/|g" settings.json
```

**2. Re-enable the pull-brief hook per repo.** `pull-brief/repos.txt` holds absolute
repo paths from the old machine and `pull-brief/state/` is not tracked, so run
this inside each repo you want briefings for:

```bash
~/.claude/hooks/pull-brief.sh on
```

Plugins are not vendored here — reinstall any you want via `/plugin`.

Stale entries in the `settings.json` permissions allowlist (old `/private/tmp`
scratchpad paths, `additionalDirectories` pointing at repos that may not exist)
are harmless: they simply never match again.

## Backing up going forward

```bash
cd ~/.claude && git add -A && git commit -m "sync config" && git push
```
