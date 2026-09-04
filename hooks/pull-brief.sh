#!/usr/bin/env bash
# pull-brief.sh — briefs you on what changed in a shared repo since you last looked.
#
# Two entry points, one engine:
#   hook          SessionStart hook. Allowlist-gated + state-gated; SILENT unless
#                 there is something worth saying. Advances the state file.
#   report [RANGE]  On-demand (the /pull-brief skill). Always prints. Never
#                 advances state, so it is safe to run repeatedly.
#   on|off|status|list   Manage which repos this is enabled for.
#
# Design: no network, no LLM, no `git fetch`. Pure local git so the SessionStart
# path stays fast enough to never be felt. The script emits FACTS; Claude reads
# them as context and does the summarizing.

set -uo pipefail

BRIEF_HOME="${HOME}/.claude/pull-brief"
ALLOWLIST="${BRIEF_HOME}/repos.txt"
IDENTITIES="${BRIEF_HOME}/identities.txt"
STATE_DIR="${BRIEF_HOME}/state"

MAX_COMMITS=40      # commits listed before we truncate
MAX_FILES=60        # files listed in the changed-file stat
MAX_MANIFEST=140    # total lines of manifest diff inlined
MAX_RANGE=250       # above this many commits we assume a branch switch, not a pull

mkdir -p "$STATE_DIR"

# ---------------------------------------------------------------- helpers

repo_root() { git rev-parse --show-toplevel 2>/dev/null; }

state_file() {
  # One state file per repo, keyed by a filesystem-safe form of its path.
  printf '%s/%s' "$STATE_DIR" "$(printf '%s' "$1" | sed 's|^/||; s|/|_|g')"
}

is_enabled() {
  [ -f "$ALLOWLIST" ] || return 1
  grep -v '^[[:space:]]*#' "$ALLOWLIST" 2>/dev/null \
    | grep -v '^[[:space:]]*$' \
    | grep -qxF "$1"
}

# Build one PCRE alternation matching every author string that counts as "me".
my_authors() {
  local pats=() email name local_part
  email=$(git config user.email 2>/dev/null || true)
  name=$(git config user.name 2>/dev/null || true)
  [ -n "$email" ] && { pats+=("$(printf '%s' "$email" | sed 's/[.[\*^$+?(){}|\\]/\\&/g')")
                       local_part="${email%%@*}"
                       [ ${#local_part} -ge 4 ] && pats+=("$(printf '%s' "$local_part" | sed 's/[.[\*^$+?(){}|\\]/\\&/g')"); }
  [ -n "$name" ] && [ ${#name} -ge 4 ] && pats+=("$(printf '%s' "$name" | sed 's/[.[\*^$+?(){}|\\]/\\&/g')")
  if [ -f "$IDENTITIES" ]; then
    while IFS= read -r line; do
      case "$line" in ''|\#*) continue ;; esac
      pats+=("$line")
    done < "$IDENTITIES"
  fi
  [ ${#pats[@]} -eq 0 ] && return 1
  local IFS='|'; printf '%s' "${pats[*]}"
}

# ---------------------------------------------------------------- tripwires
#
# Deterministic file-pattern matches. "Do I need to reinstall / re-migrate /
# re-configure" must never be an LLM judgment call, so it is a grep.

tripwires() {
  local range="$1" files hits=0
  files=$(git diff --name-only "$range" 2>/dev/null) || return 0
  [ -z "$files" ] && return 0

  _tw() { # label, suggested-command, regex
    local matched
    matched=$(printf '%s\n' "$files" | grep -E "$3" || true)
    [ -z "$matched" ] && return 0
    hits=1
    printf '  [%s] %s\n' "$1" "$2"
    printf '%s\n' "$matched" | sed 's/^/        /'
  }

  _tw "DEPS"      "reinstall dependencies" \
      '(^|/)(package(-lock)?\.json|yarn\.lock|pnpm-lock\.yaml|Gemfile(\.lock)?|requirements[^/]*\.txt|poetry\.lock|Pipfile(\.lock)?|pyproject\.toml|Podfile(\.lock)?|go\.(mod|sum)|Cargo\.(toml|lock)|composer\.(json|lock))$'
  _tw "SPM"       "Xcode will resolve packages on next build; ⇧⌘K first if it misbehaves" \
      '(project\.pbxproj|Package\.(swift|resolved))$'
  _tw "MIGRATION" "run pending database migrations" \
      '(^|/)(db/migrate/|migrations?/|db/(structure\.sql|schema\.rb)|prisma/schema\.prisma|alembic/)'
  _tw "RUNTIME"   "your language/tool version pin moved — re-shim before building" \
      '(^|/)(\.nvmrc|\.ruby-version|\.python-version|\.tool-versions|\.node-version|runtime\.txt)$'
  _tw "ENV"       "new or changed environment variables — diff against your local .env" \
      '(^|/)\.env(\.[a-z]+)?(\.(example|sample|template))?$'
  _tw "CONTAINER" "rebuild containers" \
      '(^|/)(Dockerfile[^/]*|docker-compose[^/]*\.ya?ml|\.dockerignore)$'
  _tw "BUILDCFG"  "build/tooling config changed — a stale cache may bite you" \
      '(^|/)(tsconfig[^/]*\.json|next\.config\.[jtm]s|vite\.config\.[jtm]s|webpack\.config\.[jtm]s|babel\.config\.[jtm]s|jest\.config\.[jtm]s|tailwind\.config\.[jtm]s|eslint[^/]*|\.prettierrc[^/]*)$'
  _tw "CI"        "CI pipeline changed — expect different checks on your next PR" \
      '(^|/)(\.github/workflows/|\.gitlab-ci\.yml|Jenkinsfile|\.circleci/)'
  _tw "AI-RULES"  "agent instructions changed — re-read before your next AI-assisted change" \
      '(^|/)(CLAUDE\.md|AGENTS\.md|\.cursorrules|\.claude/)'

  return $hits
}

# ---------------------------------------------------------------- the briefing

emit_brief() {
  local base="$1" head="$2" root="$3" mode="$4"
  local mine_pat total foreign_n mine_n

  mine_pat=$(my_authors) || mine_pat=''
  total=$(git rev-list --count "$base..$head" 2>/dev/null || echo 0)
  [ "$total" -eq 0 ] && return 1

  if [ -n "$mine_pat" ]; then
    foreign_n=$(git rev-list --count --no-merges --perl-regexp --author="^(?!.*($mine_pat))" "$base..$head" 2>/dev/null || echo 0)
    mine_n=$(git rev-list --count --no-merges --perl-regexp --author="($mine_pat)" "$base..$head" 2>/dev/null || echo 0)
  else
    foreign_n="$total"; mine_n=0
  fi

  local tw_out tw_found=0
  tw_out=$(tripwires "$base..$head"); [ -n "$tw_out" ] && tw_found=1

  # Nothing from anyone else and no tripwires => not worth interrupting you.
  if [ "$mode" = "hook" ] && [ "$foreign_n" -eq 0 ] && [ "$tw_found" -eq 0 ]; then
    return 1
  fi

  echo "=============================================================="
  echo "PULL BRIEF — $(basename "$root") @ $(git rev-parse --abbrev-ref HEAD)"
  echo "=============================================================="
  if [ "$mode" = "hook" ]; then
    echo "INSTRUCTION TO CLAUDE: before answering anything else this turn,"
    echo "summarize this briefing for the user in a few lines — lead with any"
    echo "action they must take (installs, migrations, config), then the"
    echo "must-know changes. Be brief. If ACTION REQUIRED is empty, say so in"
    echo "one line. Do not dump this raw block back to them."
  fi
  echo
  echo "Range: ${base:0:9}..${head:0:9}  ($total commits — $foreign_n by others, $mine_n by you)"
  echo

  if [ "$tw_found" -eq 1 ]; then
    echo "--- ACTION REQUIRED (deterministic file matches, not inference) ---"
    printf '%s\n' "$tw_out"
    echo
  else
    echo "--- ACTION REQUIRED: none. No dependency, migration, env, or config file moved. ---"
    echo
  fi

  if [ "$foreign_n" -gt 0 ]; then
    echo "--- COMMITS BY OTHERS ---"
    git log --no-merges --perl-regexp ${mine_pat:+--author="^(?!.*($mine_pat))"} \
      --format='  %h  %<(18,trunc)%an  %ad  %s' --date=short \
      -n "$MAX_COMMITS" "$base..$head" 2>/dev/null
    [ "$foreign_n" -gt "$MAX_COMMITS" ] && echo "  … $((foreign_n - MAX_COMMITS)) more not listed"
    echo
  fi

  if [ "$mine_n" -gt 0 ]; then
    echo "--- YOUR OWN COMMITS IN THIS RANGE (context only; critical items are above) ---"
    git log --no-merges --perl-regexp ${mine_pat:+--author="($mine_pat)"} \
      --format='  %h  %ad  %s' --date=short -n 15 "$base..$head" 2>/dev/null
    [ "$mine_n" -gt 15 ] && echo "  … $((mine_n - 15)) more"
    echo
  fi

  echo "--- CHANGED FILES ---"
  git diff --stat=100 "$base..$head" 2>/dev/null | head -n "$MAX_FILES"
  local nfiles; nfiles=$(git diff --name-only "$base..$head" 2>/dev/null | wc -l | tr -d ' ')
  [ "$nfiles" -gt "$MAX_FILES" ] && echo "  … $((nfiles - MAX_FILES)) more files"
  echo

  # Inline the manifest diffs themselves — this is where "which package moved
  # and to what version" actually lives, and it is small enough to include.
  local manifests
  manifests=$(git diff --name-only "$base..$head" 2>/dev/null \
    | grep -E '(^|/)(package\.json|Gemfile|pyproject\.toml|requirements[^/]*\.txt|go\.mod|Cargo\.toml|composer\.json|\.env\.(example|sample|template)|\.nvmrc|\.ruby-version|\.tool-versions)$' || true)
  if [ -n "$manifests" ]; then
    echo "--- MANIFEST DIFFS ---"
    # shellcheck disable=SC2086
    git diff --unified=1 "$base..$head" -- $(printf '%s ' $manifests) 2>/dev/null \
      | grep -E '^[+-][^+-]|^\+\+\+|^---' | head -n "$MAX_MANIFEST"
    echo
  fi

  echo "=============================================================="
  return 0
}

# ---------------------------------------------------------------- modes

cmd_hook() {
  # SessionStart delivers its JSON on stdin; honour its cwd.
  local input cwd
  input=$(cat 2>/dev/null || true)
  cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)
  [ -n "$cwd" ] && [ -d "$cwd" ] && cd "$cwd" 2>/dev/null

  local root; root=$(repo_root) || exit 0
  [ -z "$root" ] && exit 0
  is_enabled "$root" || exit 0

  local head branch sf last_sha last_branch base
  head=$(git rev-parse HEAD 2>/dev/null) || exit 0
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  sf=$(state_file "$root")

  if [ -f "$sf" ]; then
    last_sha=$(sed -n '1p' "$sf"); last_branch=$(sed -n '2p' "$sf")
  else
    # First sight of this repo: establish a baseline silently rather than
    # briefing on the entire history.
    printf '%s\n%s\n' "$head" "$branch" > "$sf"; exit 0
  fi

  printf '%s\n%s\n' "$head" "$branch" > "$sf"   # advance state regardless

  [ "$last_sha" = "$head" ] && exit 0
  # Branch switches are not pulls — re-baseline without noise.
  [ "$last_branch" != "$branch" ] && exit 0

  if git merge-base --is-ancestor "$last_sha" "$head" 2>/dev/null; then
    base="$last_sha"
  else
    # Rebased or force-pushed upstream: brief from the common ancestor.
    base=$(git merge-base "$last_sha" "$head" 2>/dev/null) || exit 0
  fi

  local n; n=$(git rev-list --count "$base..$head" 2>/dev/null || echo 0)
  [ "$n" -eq 0 ] && exit 0
  [ "$n" -gt "$MAX_RANGE" ] && exit 0    # looks like a checkout, not a pull

  emit_brief "$base" "$head" "$root" "hook" || exit 0
  exit 0
}

cmd_report() {
  local root; root=$(repo_root)
  if [ -z "$root" ]; then echo "pull-brief: not inside a git repository." >&2; exit 1; fi
  local head base
  head=$(git rev-parse HEAD)
  if [ -n "${1:-}" ]; then
    base=$(git rev-parse "$1" 2>/dev/null) || { echo "pull-brief: cannot resolve '$1'" >&2; exit 1; }
  else
    local sf; sf=$(state_file "$root")
    base=$([ -f "$sf" ] && sed -n '1p' "$sf" || true)
    # Fall back to "whatever landed in the last week" when there is no state.
    if [ -z "$base" ] || ! git cat-file -e "$base" 2>/dev/null; then
      base=$(git rev-list -n1 --before='7 days ago' HEAD 2>/dev/null)
    fi
    [ -z "$base" ] && base=$(git rev-list --max-parents=0 HEAD | head -1)
  fi
  git merge-base --is-ancestor "$base" "$head" 2>/dev/null || base=$(git merge-base "$base" "$head")
  if ! emit_brief "$base" "$head" "$root" "report"; then
    echo "PULL BRIEF — $(basename "$root"): nothing new since ${base:0:9}."
  fi
}

cmd_on() {
  local root; root=$(repo_root)
  [ -z "$root" ] && { echo "pull-brief: not inside a git repository." >&2; exit 1; }
  if is_enabled "$root"; then echo "pull-brief: already enabled for $root"; else
    printf '%s\n' "$root" >> "$ALLOWLIST"; echo "pull-brief: enabled for $root"
  fi
  # Baseline at enable time so you are not briefed on pre-existing history.
  printf '%s\n%s\n' "$(git rev-parse HEAD)" "$(git rev-parse --abbrev-ref HEAD)" > "$(state_file "$root")"
  echo "pull-brief: baseline set to $(git rev-parse --short HEAD) on $(git rev-parse --abbrev-ref HEAD)"
}

cmd_off() {
  local root; root=$(repo_root)
  [ -z "$root" ] && { echo "pull-brief: not inside a git repository." >&2; exit 1; }
  if is_enabled "$root"; then
    grep -vxF "$root" "$ALLOWLIST" > "$ALLOWLIST.tmp" && mv "$ALLOWLIST.tmp" "$ALLOWLIST"
    echo "pull-brief: disabled for $root"
  else
    echo "pull-brief: was not enabled for $root"
  fi
}

cmd_status() {
  local root; root=$(repo_root)
  echo "pull-brief allowlist ($ALLOWLIST):"
  grep -v '^[[:space:]]*#' "$ALLOWLIST" 2>/dev/null | grep -v '^[[:space:]]*$' | sed 's/^/  /' || echo "  (empty)"
  echo
  if [ -n "$root" ]; then
    if is_enabled "$root"; then
      local sf; sf=$(state_file "$root")
      echo "this repo ($root): ENABLED"
      [ -f "$sf" ] && echo "  baseline: $(sed -n '1p' "$sf" | cut -c1-9) on branch $(sed -n '2p' "$sf")" \
                   || echo "  baseline: not yet set (first session will establish it silently)"
    else
      echo "this repo ($root): disabled"
    fi
  else
    echo "(not inside a git repository)"
  fi
}

case "${1:-report}" in
  hook)   shift; cmd_hook "$@" ;;
  report) shift; cmd_report "${1:-}" ;;
  on|enable)   cmd_on ;;
  off|disable) cmd_off ;;
  status|list) cmd_status ;;
  *) echo "usage: pull-brief.sh {hook|report [REV]|on|off|status}" >&2; exit 1 ;;
esac
