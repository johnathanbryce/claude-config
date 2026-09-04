---
description: Generate unit tests for uncommitted changes, in whatever language and test framework the repo already uses. Writes complete tests and runs them to green by default; "scaffold" mode instead creates named stub cases for me to implement. Use when changed work needs test coverage before commit. Pushes back when the changed work does not genuinely warrant tests.
argument-hint: "[language] [scaffold]"
allowed-tools: Read, Grep, Glob, Write, Edit, Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(pytest:*), Bash(python -m pytest:*), Bash(npx jest:*), Bash(npx vitest:*), Bash(npm test:*), Bash(yarn test:*), Bash(pnpm test:*), Bash(swift test:*), Bash(bundle exec rspec:*), Bash(bundle exec rails test:*), Bash(bin/rails test:*), Bash(rspec:*), Bash(go test:*), Bash(cargo test:*), Bash(dotnet test:*), Bash(mvn test:*), Bash(gradle test:*), Bash(./gradlew test:*), Bash(xcodebuild test:*), Bash(make test:*)
---

Create unit tests for the uncommitted work in this repo.

## Arguments

$ARGUMENTS may contain, in any order:

- A language name (`python`, `swift`, `ruby`, `go`, whatever the repo contains) — only generate tests for files in that language. Default: every changed language that warrants tests.
- `scaffold` — instead of complete tests, create the test file, enumerate the cases as named failing stubs with a one-line comment stating the expected behavior, and fully implement exactly ONE case per file as a pattern anchor. I write the rest. Default (no `scaffold`): **full mode** — complete, passing tests.

## Detect the stack — do this first

This skill is language-agnostic. Never assume a language, and never remark on which languages are or aren't present — just work in the one the repo uses.

1. Determine the language of each changed file from its extension, and confirm against the repo's manifest (`pyproject.toml`, `package.json`, `Package.swift`, `Gemfile`, `go.mod`, `Cargo.toml`, `*.csproj`, `pom.xml`, `build.gradle`, etc.).
2. Determine the test runner from the repo's own config and existing test files — not from a built-in mapping. The runner the repo already invokes is the runner to use, even if it isn't the ecosystem default.
3. A repo may be several stacks at once (e.g. Swift client + Rails API). Handle each changed file in its own language and framework, in one run. Don't pick a winner, and don't ask which one I meant.
4. If a changed file's language has no test setup in this repo at all, stop and propose the minimal setup before writing tests — same as any other language.

## Scope — what gets tests

1. Run `git status --porcelain --untracked-files=all` and `git diff` to collect modified and new files (the flag is required — untracked directories otherwise collapse to one line and their files are missed).
2. Include only source files containing testable logic: branching, error paths, data transformation, calculations, request handlers.
3. Exclude — and say so in the report: config files, type-only/interface files, generated code, plain markup/styling, trivial getters/pass-through wrappers, existing test files, docs/markdown.
4. Never write tests for unchanged code. If a changed file has no testable logic, skip it and say why.

## Judgment gate — not every change needs tests

Tests are the default here, not an obligation. Before writing anything, decide whether this changeset genuinely warrants tests, and say so plainly if it doesn't:

- Whole changeset is untestable by nature (config, copy, styling, wiring, dep bumps, renames, type-only changes) → write nothing, report why, stop.
- Logic is real but so thin a test would only restate the implementation → recommend skipping rather than producing a tautological test.
- Meaningful coverage would need heavy mocking of code I own, or a test harness the repo doesn't have → name that cost and ask before building it.
- The change is genuinely covered by an integration or e2e test instead → say that; don't force it into a unit test's shape.

Calibrate the call to THIS repo, not to testing principle in general. Before deciding, check what the repo actually does:

- `git log --oneline -20 -- <changed file or its directory>` and `git log --name-only -15 -- <dir>` — when files like these changed before, did test files change in the same commits? A module the repo has never tested across many commits is weak grounds for insisting on tests now.
- Look for existing tests covering the changed files' neighbours (same directory, same layer). Their presence, density, and depth are the local standard — match it rather than exceeding it.
- If the repo tests this layer consistently, treat tests as expected and set the bar for skipping high. If it never has, say so explicitly ("nothing in `src/routes/` has tests in the last 30 commits") and let me decide whether to start.

Report the evidence, not just the verdict — cite the commits or the neighbouring test files you looked at.

State the objection once, with reasoning, then defer: if I still want the tests, write them in full — that's my call. Never pad the run with low-value tests to look thorough. "These 3 files need tests, these 5 don't and here's why" is a better result than 8 test files.

## Match the repo, don't impose

Read the repo's existing tests before writing anything, and answer these from the code rather than from ecosystem convention:

- Where do test files live, and what are they named? (`tests/` vs `__tests__/` vs `spec/` vs co-located; `test_*.py` vs `*.test.ts` vs `*_test.go` vs `*Tests.swift`.)
- Which runner and assertion style does the repo actually invoke — from its scripts, CI config, and Makefile, not from what the language usually uses?
- What are the local setup idioms: shared fixtures, factories, builders, setup/teardown hooks, parametrized/table-driven cases? Reuse the ones that exist instead of inventing parallel machinery.
- How does the repo fake its seams — DI, protocol/interface doubles, a mocking library, recorded HTTP fixtures? Match it.

The table below is a starting point for common ecosystems, not the set of languages this skill supports. **If the changed language isn't listed, infer its conventions from the repo and proceed silently — never note that it's missing here, and never compare it to the languages that are.** Where the table and the repo disagree, the repo wins.

| Language | Typical runner | Typical location / naming | Idioms to look for |
|---|---|---|---|
| Python | pytest | `tests/`, `test_*.py` | `conftest.py` fixtures, `parametrize` |
| TS / JS | Jest or Vitest | `__tests__/`, `*.test.ts` | `describe`/`it`, module mocks, setup files |
| Swift | Swift Testing or XCTest | `Tests/`, `*Tests.swift` | `@Test`/`#expect` vs `XCTestCase`, protocol-based doubles |
| Ruby / Rails | RSpec or Minitest | `spec/` or `test/`, `*_spec.rb` / `*_test.rb` | factories vs fixtures, request vs model specs |
| Go | `go test` | co-located `*_test.go` | table-driven cases, interface doubles |
| Rust | `cargo test` | `#[cfg(test)]` module, `tests/` | `#[test]`, `assert_eq!` |
| C# | xUnit / NUnit | `*.Tests` project | `[Fact]`/`[Theory]`, DI-injected fakes |
| Java / Kotlin | JUnit | `src/test/java` | `@Test`, Mockito at the seams |

## What a unit test must be

- Tests public behavior through the unit's interface — never internals or implementation details.
- Per unit: one happy path plus the failure modes that matter (invalid input, missing resource, boundary values).
- Test names state scenario and expectation (e.g. `test_create_comment_on_missing_task_returns_404`), phrased in the naming style the repo already uses. Arrange–act–assert shape, one behavior per test.
- Mock at the seams (injected stores, clients, config) — never mock what you own and can call directly.

## Full mode only

After writing, run the new tests with the repo's own runner. If a test fails because the TEST is wrong, fix the test — capped at 3 fix attempts per test file. After the 3rd failed attempt, stop touching that file, mark it unresolved in the report, and move on; never loop indefinitely. If a test fails because the SOURCE is buggy, stop immediately and report the bug — never bend a test to make broken code pass.

In a multi-stack changeset, run each language's suite separately and report each result. If the repo's runner isn't in `allowed-tools`, state the exact command and run it — a one-time permission prompt is expected; never substitute a different command to avoid the prompt.

## Report

- Mode that ran, languages and runners detected, files created, and the named cases per file.
- What was skipped and why — no silent scope decisions.
- Anything you recommended against testing, stated up front rather than buried at the end.
- Full mode: the pass/fail summary from each actual test run.
