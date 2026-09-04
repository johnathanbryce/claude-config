---
description: Produce a high-level architecture view — a Mermaid tech/infra flowchart plus key flows and gaps, written to a .md file and rendered to viewable SVG + PNG images. Two modes: `pre` turns a spec/idea into a PROPOSED target architecture before building; `post` reads what you built on the current branch and draws the AS-BUILT architecture. Use `pre` to plan a build fast (e.g. after /spec) and `post` to produce an architecture artifact alongside /docs when a feature is done. Unlike /diagram (faithful transcription of a source you provide), /architect reasons about the system and makes judgment calls it flags.
argument-hint: "[pre|post] [app-flow|full-infra] [spec text or file — pre only; or an output dir/.md]"
allowed-tools: Read, Grep, Glob, Write, Edit, Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git merge-base:*), Bash(git branch:*), Bash(mmdc:*), Bash(open:*), Bash(mkdir:*)
---

Produce an architecture view from this input: $ARGUMENTS

## Mode

Pick the mode from `$ARGUMENTS`:

- **`pre`** — synthesize a PROPOSED target architecture from a spec or rough idea, before code exists.
- **`post`** — read what was built on the current branch and draw the AS-BUILT architecture.
- **If neither word is present:** infer — a spec/idea/text argument means `pre`; no build input on a
  branch with changes means `post`. If genuinely ambiguous, ask one question before proceeding.

Optional altitude token: **`app-flow`** (application logic only) or **`full-infra`** (app tier, data
stores, external services, LLM providers). If absent, choose the altitude from the material and state
which you chose in one line. For an interview/onsite plan, `full-infra` is usually right.

## `pre` mode — spec → proposed architecture

1. The spec is the rest of `$ARGUMENTS` (raw text or a path to a `.md` spec). If it references an
   existing codebase, skim the relevant code first — a proposed architecture that contradicts what's
   already there is worse than none.
2. **Refuse to invent.** If the input is too thin to visualize — no identifiable components, data
   stores, or flows — ask 1-3 targeted questions before drawing. Never manufacture an architecture
   from nothing.
3. Where the spec is silent on a real decision (auth, storage, a provider), make the reasonable
   default choice, draw it, and record every such call in **Gaps / Assumptions** — do not bury
   judgment calls inside the diagram as if they were given.

## `post` mode — code → as-built architecture

1. Scope = **what I built**: the branch diff plus uncommitted changes
   (`git diff $(git merge-base <default-branch> HEAD)` + uncommitted). If currently ON the default
   branch, fall back to uncommitted changes only and say so.
2. Use `git status --porcelain --untracked-files=all` so untracked directories don't collapse and get
   missed. **Read the in-scope files in full** — an architecture drawn from hunks alone is guesswork.
3. Draw only what the code actually shows. Render the surrounding system it connects to (a DB, an
   external API, an LLM provider it calls) as clearly-labeled **context** nodes so the diagram isn't an
   orphan — but never fabricate internals you didn't read.

## Output — ALWAYS a file, ALWAYS rendered (never just chat markdown)

The whole point is something viewable. Never stop at a Mermaid block in chat.

### 1. Write the `.md`

Compose a markdown doc with these sections in order:

1. **One line** stating mode + altitude chosen (e.g. "post / full-infra — as-built from 6 files on this branch").
2. **Mermaid flowchart** — a fenced ` ```mermaid ` block. Group by tier (client / app / data / external)
   using `subgraph`s. Node text is a short label, not a sentence.
3. **Key Flows** — the 2-3 most important request/data paths, numbered, one line each
   (e.g. "1. Upload → chunk → embed → store in Postgres").
4. **Gaps / Assumptions / Open questions** — `pre`: every default chosen where the spec was silent,
   plus anything still undecided. `post`: notable decisions, risky seams, and anything that looks
   incomplete or worth revisiting.

**Where the `.md` goes** — always inside a dedicated `diagrams/` directory (`mkdir -p diagrams`
first) so rendered artifacts never scatter at the project root:
- `post`: `diagrams/architecture.md` (renders on GitHub in the PR). Update in place if it exists —
  never a parallel `-v2`. If a destination is named in args, use that instead.
- `pre`: a named destination if given; else `diagrams/<slug>-architecture.md` (slug from the spec
  title). No repo required.

### 2. Render to SVG + PNG, then open

`mmdc` appends a chart-index suffix (`-1`) when it reads a diagram out of *markdown*, even for a single
chart — so rendering the `.md` directly yields `<file>-1.svg`, an unstable name. To get clean, stable
image names, render from a temporary pure-Mermaid `.mmd` extract instead:

```
# write just the flowchart body (no fences, no prose) to a temp .mmd
mmdc -i <file>.mmd -o <file>.svg    # crisp, zoomable — the one to view
mmdc -i <file>.mmd -o <file>.png    # universal — for pasting into decks/chat
rm <file>.mmd                        # temp; the .md keeps the canonical diagram source
open -a "Google Chrome" <file>.svg   # SVG opens sharp in the browser
```

The `.md` (with its fenced ```mermaid block) stays the canonical, editable source and the GitHub-
renderable doc; the `.mmd` is a throwaway used only to name the images cleanly.

**Gitignore the images.** The `.svg`/`.png` are regenerable build output — the `.md` is the source of
truth (and GitHub renders its Mermaid inline). On the first run inside a git repo, if these patterns
aren't already ignored, tell the user to add them to `.gitignore` so rendered images don't accumulate
in version control:

```
diagrams/*.svg
diagrams/*.png
```

Commit the `.md`; leave the images ignored.

### 3. Report in chat — briefly

State the mode/altitude line, the file paths written (`.md`, `.svg`, `.png`), and paste ONLY the
**Gaps / Assumptions** section as text (that's the part worth discussing without opening the image).
Do NOT paste the raw Mermaid block into chat — it's in the file and rendered.

### Fallback

If `mmdc` is not installed or rendering fails, still write the `.md`, then say so in one line and give
the exact install command (`npm install -g @mermaid-js/mermaid-cli`) rather than silently degrading to
a chat-only dump.

## Hard rules

- **/architect reasons; /diagram transcribes.** This skill makes and flags architectural judgment
  calls. If you were only asked to faithfully reproduce a source (image, existing diagram), that's
  `/diagram` — don't invent structure here in that case.
- Never assert a component that isn't in the spec (`pre`) or the code (`post`) without flagging it as
  an assumption.
- Keep the flowchart legible — if it exceeds ~15 nodes, raise the altitude and collapse detail into
  grouped subgraphs rather than drawing every function.
- Brevity is a feature. The diagram plus a few lines of flows and gaps beats a wall of prose. Omit any
  section that would be empty.
