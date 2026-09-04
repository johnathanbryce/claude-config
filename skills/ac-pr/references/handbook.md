# AlgaeCal dev handbook — the parts a reviewer judges

Distilled from AlgaeCal's internal dev handbook (Sections 1–9), keeping what a human reviewer
enforces and dropping what tooling enforces. **The repo always outranks this file.**

## The projects

| Project | What it is | Stack |
|---|---|---|
| Hydrogen | B2C storefront — algaecal.com and international variants | Shopify Hydrogen, React Router v7, Cloudflare Workers |
| B2B | Wholesale storefront for HCPs and OsteoStrong franchisees; account-specific pricing | Shopify Hydrogen, RR v7, Cloudflare Workers, TypeScript (`b2b-theme`), MESH backend, Builder.io |
| MESH | Data integration layer — customer, order, subscription, loyalty sync | Node.js, TypeScript, Google Cloud (Cloud Run, Cloud Functions) |
| UI Kit | Shared React component library consumed by Hydrogen and B2B | React, TypeScript, Webpack, SCSS, Storybook |

Hydrogen moved off Remix to **React Router 7**. Never review it as a Remix app.

## Branches

Long-lived: `main` (production, and what feature branches are cut from) · `release/staging` (final QA)
· `release/candidate` (QA environment; feature branches merge here when approved) · `dev` (dev
environment testing, frequently reset).

Short-lived: `feature/DEV-###-{kebab}` · `bugfix/DEV-###-{kebab}` (issue introduced in a release) ·
`hotfix/DEV-###-{kebab}` (emergency prod fix, bypasses the release cycle).

Jira auto-generates branch names and truncates them. A cut-off description is a real finding.

## Commit format

```
<type>(<scope>): DEV-### <imperative description, no trailing period>

<body — why, not what>

<footers>
<smart commit commands — ONE line, Jira key before the commands>
```

Types: `feat` `fix` `docs` `style` `refactor` `perf` `test` `build` `ci` `chore` `revert`.
`!` after type/scope for breaking, plus a `BREAKING CHANGE:` footer.

Scopes — hydrogen: `cart` `checkout` `account` `products` `components` · mesh: `customer` `order`
`product` `db` `queue` · algaecal-ui-kit: `components` `hooks` `styles` `utils`.

A Jira ticket per change is strongly encouraged; ticketless commits may become disallowed.

## PR rules

Template: **Description** (high level, so the reviewer doesn't hunt for it) · **Technical Notes /
Background** (optional — why you chose an approach, tricky code worth attention) · **Testing
Instructions** (numbered click-path, API call with real request body, or a screenshot/video) ·
**Commits** (the list).

**500-line limit**, excluding: lockfiles/`.md`/`.json`/assets · test files for a new front-end
component (never split tests across PRs) · isolated data-fetching services that must be tested end to
end · experimental/VOC features (PR optional) · verbatim code moves to a new repo · accidentally
tracked generated CSS, bundles, sourcemaps · deprecations and legacy-directory deletions. Backend
should stay under 500 with no test allowance.

## The six review criteria

What AlgaeCal reviewers are told to check, expanded into what to actually look for:

1. **Functionality** — does it do what the ticket says? Trace the happy path, then the edges: empty
   inputs, missing keys, null/undefined, off-by-one on ranges and pagination. Correctness outranks
   everything else in the report.
2. **Consistency with project patterns** — the code works and is still wrong if it invents a second way
   to do something the repo already does. Grep for the existing helper, the existing hook, the
   existing fetch wrapper. A near-duplicate is worse than either reusing or deliberately forking with
   a comment saying why.
3. **Security** — secrets in the diff, config, or log output block the review immediately. Validate
   external input at the boundary; never trust client-supplied IDs to reference things that exist.
   Errors must not leak internals.
4. **Accessibility** — genuinely not lint-covered, and explicitly in their criteria. Interactive
   elements reachable by keyboard, real `<button>`/`<a>` rather than clickable `<div>`, labels tied to
   inputs, alt text, focus not trapped or lost after an update, state changes announced.
5. **Unit test coverage** — new behavior ships with tests. A test asserting on mocks, or re-implementing
   the function's logic in its assertion, passes forever and catches nothing. The failure-mode test
   matters more than the happy path: would this test fail if the feature broke?
6. **Readability and maintainability** — a reader should predict what a function does from its
   signature. Flag names that lie. Flag unrelated refactors bundled with a behavior change: that hides
   the behavior change and is a real finding, not a style preference.

Add two the handbook implies but doesn't spell out: **what's missing from the diff** (callers, types,
migrations, the other implementation of the same interface — omissions are the expensive misses), and
**scale of the real data** (N+1 queries, unbounded selects, O(n²) over something that's 10 rows in dev
and 100k in prod).

## Code conventions worth knowing (context, not findings)

Casing: kebab for CSS names and PHP files · camelCase for JS vars/functions · Pascal/StudlyCaps for
classes · snake_case for Python. CSS uses BEM (`.block`, `.block__element`, `.block--modifier`) and
otherwise Google's style guide. Python follows PEP 8/20/257 with 79-char lines and `"""` docstrings
first in the class or function. PHP follows PSR-1/4/12. SemVer is `MAJOR.MINOR.PATCH`, tags prefixed
`v` where the repo does that.

**Do not report violations of these as review findings.** SonarQube, ESLint, and Prettier own them.
They are here so the review understands the house style, not so it duplicates a linter.

## React — deliberately thin

The handbook's React chapter is largely standard modern practice (function components, hooks, careful
dependency arrays, keys on lists, controlled inputs, `useRef` for DOM access, Context sparingly and
wrapped in a custom hook, RTL + Jest).

Three parts of it are dated. **Defer to what the repo actually does, and do not raise these as
findings:**

- **PropTypes** — removed in React 19. These are TypeScript codebases; types are the validation.
- **Enzyme** — no adapter past React 16. If the repo uses RTL, the handbook's Enzyme section is dead.
- **"Avoid inline functions in JSX"** — a micro-optimization that React Compiler makes largely moot.
  Flag an inline function only where it demonstrably breaks memoization on a hot path, never on sight.

The handbook also says to treat AI-generated code as a draft and verify correctness, security,
maintainability, licensing, and fit with existing repo patterns before opening a PR. That instruction
is the reason this skill exists.
