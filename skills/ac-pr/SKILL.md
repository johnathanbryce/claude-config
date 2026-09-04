---
description: End-of-branch audit for an AlgaeCal PR — checks branch name, audits every commit message against their format and hands back the exact git commands to fix the ones worth fixing, checks the 500-line limit and its exceptions, runs a review pass against AlgaeCal's six review criteria, and writes the PR body in their template. Use before opening a PR in Bitbucket on any AlgaeCal repo.
argument-hint: "[base branch, default main] [nobody to skip PR body] [quick]"
allowed-tools: Read, Grep, Glob, Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git branch:*), Bash(git merge-base:*), Bash(git rev-parse:*), Bash(git ls-files:*)
---

Audit the current branch before opening a Bitbucket PR. Read `references/handbook.md` first — it holds AlgaeCal's documented standards.

Base branch is `main` unless `$ARGUMENTS` names another. AlgaeCal cuts feature branches from `main` and merges up through `dev` → `release/candidate` → `release/staging`, so `main` measures the change itself. If the branch was clearly cut from something else, say so and use that instead.

## Recon before judgment

The repo outranks this skill. Before checking anything, look for:

- `CLAUDE.md`, `CONTRIBUTING.md`, `README.md`
- `commitlint.config.*`, `.husky/`
- `.eslintrc*` / `eslint.config.*`, `.prettierrc*`, `sonar-project.properties`, `.editorconfig`
- Bitbucket PR template (`.bitbucket/`, `pull_request_template.md`)

Where any of these conflict with the handbook, follow the repo and name the file that overrode it. Note anything the repo enforces that the handbook doesn't mention.

## What to check

### 1. Branch name

`{feature|bugfix|hotfix}/DEV-###-{kebab-case-description}`. Flag a missing ticket, wrong prefix, non-kebab description, or a Jira-generated name that got truncated mid-word.

### 2. Commit messages and remediation

`git log --format='%H%n%s%n%b%n---' <base>..HEAD`, then audit each commit against the format in
`references/handbook.md`: type present and correct for what the commit actually did, scope valid for
the project, `DEV-###` key present, imperative mood, no trailing period, breaking changes carrying both
`!` and a `BREAKING CHANGE:` footer.

**Judge whether the fix is worth it before proposing one.** A missing Jira key on one commit in a
branch whose name already carries the ticket is a nit, not a blocker. Rewriting six commits to fix
capitalization is not worth the risk. Rank each finding:

- **Worth fixing** — wrong or misleading description, missing Jira key on every commit, a breaking
  change with no marker
- **Leave it** — cosmetic drift on one commit in an otherwise clean branch

**Smart Commit commands cannot be fixed by rewording.** They are processed when the commit is pushed.
If a transition was missed or wrong, rewording will not re-fire it — say so, and tell John to move the
ticket in Jira by hand instead.

#### Working out whether it is safe to rewrite

Run `git rev-parse --abbrev-ref --symbolic-full-name @{u}` and `git log @{u}..HEAD --oneline`.

- **No upstream, or every bad commit is ahead of the upstream** — safe, nothing has been shared.
- **Bad commits already pushed** — rewriting means a force-push. Say this plainly, name the risk (it
  rewrites history others may have pulled, and AlgaeCal protects `main`, `master`, and `develop`
  against exactly this), and only give the commands if John says to proceed. Never propose a
  force-push on a protected or shared branch — the fix there is a follow-up commit, not a rewrite.

#### The commands to give him

Spell these out in full — assume he does not remember the syntax and will paste what you write.

**Only the most recent commit is wrong, not pushed:**

```
git commit --amend -m "fix(cart): DEV-123 Prevent duplicate line items"
```

**Several commits are wrong, not pushed:**

```
git rebase -i <base>
```

Then in the editor: change `pick` to `reword` (or `r`) on each line to fix, leave the rest, save and
close. Git reopens the editor once per rewording commit — type the new message, save, close, repeat.
Give him the exact replacement message for each commit so he can paste them in order, listed oldest
first to match the rebase order. If he gets lost mid-rebase: `git rebase --abort` returns everything
to how it was.

**Already pushed, and he has confirmed he wants to proceed:**

```
git push --force-with-lease
```

Always `--force-with-lease`, never `--force` — it refuses if someone else pushed in the meantime.

### 3. The 500-line limit

`git diff --numstat <base>...HEAD`. Report the total, then the total after excluding what the handbook exempts:

- Lockfiles, `.md`, `.json`, and asset files — never counted
- Test files for a **new front-end component** — not counted, and never split across PRs
- Generated CSS, build bundles, source maps that got tracked accidentally
- Pure code moves between repos, and deletions of legacy directories

If the adjusted count is over 500, state whether one of the remaining exceptions applies (isolated end-to-end data-fetching service, experimental/VOC feature) or whether the PR should genuinely be split — and if it should, propose the split.

Backend changes should stay under 500 with no test-file allowance.

### 4. Review pass

Apply the six criteria AlgaeCal reviewers use — functionality, consistency with project patterns, security, accessibility, unit test coverage, readability — using the detail in `references/handbook.md`.

**Do not report lint-level findings.** Indent width, BEM class spelling, alphabetized CSS, semicolons, `const` vs `var`, line length: SonarQube and ESLint own those and will disagree with you eventually. Report what a human reviewer would catch and a linter can't.

Read whole files for anything nontrivial. Grep for callers of every changed signature — the expensive misses are omissions, not errors.

Skip this section if `$ARGUMENTS` contains `quick`.

### 5. Testing instructions

Derive them from the diff: which route, page, or endpoint changed, and what a reviewer clicks or calls to see it. For an API change, produce the method, path, and a realistic request body. If you can't derive a real path, say so and leave a `TODO(John)` rather than inventing one.

## Output

A terminal report first:

- **Branch name** — pass, or what's wrong
- **Commits** — count, which break format, and for the ones worth fixing: the exact commands, the replacement messages in rebase order, and whether a force-push is involved
- **Size** — raw total, adjusted total, verdict against 500 with the exception named
- **Review** — findings ranked **Blocker** (correctness, security) → **Should fix** → **Nit**, each as `file:line` plus one sentence on the issue and one on why it matters
- **Verdict** — Ready to open · Ready with nits · Not ready, plus the one thing to fix first

Then, unless `$ARGUMENTS` contains `nobody`, the PR body as a fenced markdown block to paste into Bitbucket, in AlgaeCal's template:

```
## Description
## Technical Notes / Background
## Testing Instructions
## Commits
```

Leave `Technical Notes / Background` out when the change is straightforward — the handbook marks it optional. Never invent a Jira link; use the key from the branch.

This skill reports and writes text. **It never edits code, never commits, never rebases, and never pushes** — including when it has found commits worth rewording. Rewriting git history as a side effect of an audit is how work gets lost, and the commands are short enough to paste. John runs them.

Bitbucket has no assumable CLI, so the PR body is for him to paste too.
