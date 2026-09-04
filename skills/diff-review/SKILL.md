---
description: Review working-tree changes against my personal code-review standards. Use when asked to review changes or before a commit/PR. Optionally scoped to a path argument.
argument-hint: "[optional path to scope the review]"
allowed-tools: Read, Grep, Glob, Bash(git status:*), Bash(git diff:*), Bash(git log:*)
---

Review the current working-tree changes. If $ARGUMENTS is provided, scope the review to that path.

## Process

1. Run `git status --porcelain` and `git diff` to collect the changes (include untracked files).
2. For anything nontrivial, Read the full file — never review a hunk without its surrounding context.
3. If the diff touches `.tsx`/`.jsx`/React hooks, also read `references/react.md` and apply it.
4. Apply the standards below. Report findings only — never edit code during a review.

## Line-level standards

1. **Correctness first.** Trace the happy path, then hunt the edges: empty inputs, missing keys, None/undefined, off-by-one on ranges and pagination boundaries. A correctness finding outranks everything else in the review.
2. **Error handling is part of the API contract.** Failures must return deliberate, consistent shapes — right status code, structured error body, nothing leaking internals. No bare 500s, no silently swallowed exceptions.
3. **Validate at the boundary.** External input is untrusted until it passes schema/type validation at the edge (e.g. Pydantic request models). Never trust client-supplied IDs to reference things that exist — check referential integrity.
4. **No secrets in the diff.** API keys, tokens, connection strings, or credentials in code, config, or log output block the review immediately.
5. **Names carry meaning.** A reader should predict what a function does from its signature alone. Vague names (`data`, `handle`, `process`) or names that lie about behavior get flagged.
6. **Seams over hard-wiring.** Dependencies (stores, clients, config) should be injectable, not constructed inline where they're used — otherwise the code can't be tested or swapped later.
7. **No leftover scaffolding.** Debug prints, commented-out code, unused imports, and dead branches don't ship. Flag only at review time, never mid-debugging.
8. **New behavior ships with tests.** An endpoint or function without at least a happy-path test and one failure-mode test isn't done — it's owed.

## The senior lens

Line-level correctness is table stakes. These are the questions that separate a senior review from a linter, and most of them are answered by reading code the diff *doesn't* touch.

1. **What's missing from the diff?** The most expensive review misses are omissions, not errors. Grep for callers of every changed signature. Did the types, the migration, the feature-flag cleanup, the docs, the other implementation of the same interface get updated? A diff that reads perfectly can still be half a change.
2. **Single source of truth.** Any value stored in two places will drift — that's the general form of derived-state-in-an-effect, denormalized DB columns, and cached values with no invalidation. Ask: can this be computed instead of stored? If it must be stored, what keeps the copies honest?
3. **Blast radius.** Who else depends on this? Is it a breaking change to a published contract (API response, DB schema, exported function)? Can old and new coexist during a rollout, or does this need old clients dead first?
4. **Ordering and concurrency.** Two of these at once — two requests, two clicks, two workers — what breaks? Look for read-modify-write without a lock or transaction, non-idempotent handlers, and async results that can land out of order.
5. **Does it belong here?** Right layer, right module. Business logic in a route handler, a fetch inside a UI component, a domain rule in a utility file — the code works and is still in the wrong place. Also flag the reverse: an abstraction introduced for one caller.
6. **Reuse before invention.** Does this hand-rolled helper already exist in the codebase? A near-duplicate is worse than either using the original or deliberately forking it with a comment saying why.
7. **Scale of the real data.** Loops that issue queries (N+1), unbounded `SELECT` with no pagination, `O(n²)` over something that's 10 items in dev and 100k in prod. Ask what n actually is in production.
8. **What does the on-call see?** When this fails at 3am, is there a log line with enough context to act on, or a silent catch? Errors should be observable and attributable.
9. **Do the tests test the thing?** A test that asserts on mocks, or re-implements the function's logic in the assertion, passes forever and catches nothing. The failure-mode test matters more than the happy path. Would this test fail if the feature broke?
10. **Reviewability.** Unrelated refactors bundled with behavior changes hide the behavior change. Say so — it's a real finding, not a style preference.

## Report

- Rank findings by severity: **Blocker** (correctness, security) → **Should fix** (error handling, missing tests, seams) → **Nit** (naming, scaffolding, style).
- Each finding: `file:line`, one sentence on the issue, one sentence on why it matters.
- End with a verdict — **Approve**, **Approve with nits**, or **Request changes** — plus the single most important fix if changes are requested.
