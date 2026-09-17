---
description: Write the title and body for a pull request covering the work on the current branch — reads the branch diff, follows the repo's own PR template when one exists, and offers to open the PR with gh. Succinct and behavior-level, never a narration of the diff. Use at PR time on any repo except AlgaeCal (use /ac-pr there).
argument-hint: "[base branch, default the remote's default branch] [draft] [nocreate]"
allowed-tools: Read, Grep, Glob, Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git branch:*), Bash(git merge-base:*), Bash(git rev-parse:*), Bash(git ls-files:*), Bash(gh repo view:*), Bash(gh pr view:*), Bash(gh pr create:*)
disallowed-tools: Task, WebSearch, WebFetch
---

Write the PR title and body for the work on this branch.

## Arguments

`$ARGUMENTS` may contain, in any order:

- a **base branch** name — what the PR merges into. Default: the remote's default branch.
- `draft` — open the PR as a draft.
- `nocreate` — print the title and body only; skip the offer to open the PR.

## Scope

1. Base branch: `$ARGUMENTS` if it names one, else `gh repo view --json defaultBranchRef`, else
   `git rev-parse --abbrev-ref origin/HEAD`, else `main`. Say which base you measured against.
2. The change is `git diff $(git merge-base <base> HEAD)` plus uncommitted work — use
   `git status --porcelain --untracked-files=all`, since untracked directories otherwise collapse
   to a single line and their files are missed.
3. If HEAD is the base branch itself, say so and describe the uncommitted work only.
4. `git log --oneline <base>..HEAD` for the shape of the work; commit subjects are a hint about
   intent, not a substitute for reading the code.

## Read cap

This skill runs on a metered credit budget.

- Read in full only the files where behavior actually changed — at most ten.
- Past that, work from the diff and the commit subjects, and say in the report that file coverage
  was capped.
- One pass. No subagents, no web.

## Repo template wins

Glob for a PR template before writing anything:

```
.github/PULL_REQUEST_TEMPLATE.md   .github/pull_request_template.md
.github/PULL_REQUEST_TEMPLATE/*.md  docs/PULL_REQUEST_TEMPLATE.md
PULL_REQUEST_TEMPLATE.md            pull_request_template.md
```

If one exists, fill **its** headings in **its** order and name the file you followed. Leave its
checklists intact — tick a box only when the diff or a test run proves the item; leave the rest
unticked rather than guessing. Still write a title, which templates rarely cover.

## Default structure

When there is no template:

- **Title** — one line, imperative, under ~70 characters. The change, not the area.
- **Summary** — why this exists and what it does, two or three sentences.
- **Changes** — grouped by area, described at the behavior level.
- **How it was tested** — real evidence only: a test run that actually happened, a manual check
  that was actually performed. If nothing was verified, write "Not verified" and say what a
  reviewer should exercise.
- **Notes for reviewers** — risk areas, decisions worth scrutiny, follow-ups left out deliberately.
  Omit the section when there is genuinely nothing to say.

## Hard rules

- Describe **behavior**, never narrate the diff. "Changed line 42 of store.py" is not a PR
  description.
- Never invent. Every claim traces to code you read. Never claim a test passed unless you saw it
  pass in this session — the diff showing a test file is not evidence it was run.
- Omit empty sections. Brevity is a feature: a reviewer should be able to read this in under a
  minute and know what to look at.

## Opening the PR

1. Always print the title and body in chat first, in a copy-pasteable block.
2. Stop before `gh` if `nocreate` was passed.
3. **Never push.** If `git rev-parse --abbrev-ref @{u}` fails, the branch has no upstream — print
   the exact `git push -u origin <branch>` command for John to run, and stop.
4. If `gh pr view --json url,state` shows a PR already open for this branch, report its URL and
   stop. Never open a second one.
5. Otherwise ask whether to open it. Only on an explicit yes, write the body to a file in the
   session scratchpad and run:
   `gh pr create --base <base> --title "<title>" --body-file <path>` (add `--draft` for `draft`).
6. Report the URL `gh` returns.

## Report

The base branch used, the template file followed (or that none was found), anything the read cap
excluded, and any claim you could not verify.
