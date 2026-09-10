---
description: Cheap unit tests for an AlgaeCal PR — writes Jest + React Testing Library tests for the logic changed on the current branch versus its base, runs only the new tests once, and reports. Fixed TypeScript/Jest stack, no detection, no fix loops, no subagents, no web. Use on the work machine before /ac-pr. For any other repo use /unit-tests.
argument-hint: "[base branch, default main]"
allowed-tools: Read, Grep, Glob, Write, Edit, Bash(git status:*), Bash(git diff:*), Bash(git merge-base:*), Bash(git rev-parse:*), Bash(npx jest:*)
disallowed-tools: Task, WebSearch, WebFetch
effort: medium
---

Write unit tests for the work on this branch. Base branch: $ARGUMENTS (default `main`).

This skill runs on a metered credit budget. Every rule below exists to keep the token count down:
read little, write once, run once, stop.

## Stack — fixed, do not detect

TypeScript. Jest. React Testing Library for components. Do not inspect `package.json`, CI config,
or the Jest config to confirm this. If a test file you read shows a different runner, say so in
the report and proceed with the runner that file uses.

## Scope — the branch diff

```
git merge-base <base> HEAD
git diff --name-only <merge-base>...HEAD
git status --porcelain --untracked-files=all
```

Candidates are the changed or added `.ts` / `.tsx` files from both lists that contain logic:
branching, data transformation, calculations, request handlers, hooks with state or effects.

Skip without reading, and list in the report: existing test files, `*.d.ts` and type-only
files, `*.stories.*`, styles, config, generated code, and components that are markup only.

## Reading cap

Read only:

1. The candidate files.
2. **One** existing test file — the nearest to the first candidate by directory. Copy its
   location convention, naming, imports, and mocking style. If none exists in the repo, co-locate
   as `<name>.test.ts(x)` beside the source.
3. At most two directly imported modules per candidate, and only when a type or signature is
   needed to write the test.

Never crawl the repo, never read git history, never spawn a subagent.

## Tests — AlgaeCal's bar (handbook review criterion 5)

Would this test fail if the feature broke? That is the only question. Per unit: one happy path
plus the failure modes that matter — invalid input, missing data, boundary values. The failure-mode
test matters more than the happy path.

- Test public behavior through the unit's interface, never internals.
- Never assert on a mock, and never restate the function's logic in the assertion. Both pass
  forever and catch nothing.
- Mock at the seams (injected clients, fetchers, config). Never mock what you own and can call.
- Arrange–act–assert, one behavior per test, names that state scenario and expectation.
- Adding cases to an existing test file for a changed unit is fine; use Edit.

## Run once

Run only the files you wrote or edited:

```
npx jest <path> [<path> ...]
```

Never the whole suite. Do not fix failures. Do not re-run. If a test fails, the verbatim failure
goes in the report and John decides — a failing test may mean the source is wrong, which is a
finding, not a bug in the test.

## Report

- Files created or edited, with the named cases per file.
- Files skipped and why, one line each.
- The Jest summary line and any failure output, verbatim.
