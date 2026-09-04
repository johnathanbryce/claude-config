#!/usr/bin/env bash
# secrets-guard.sh — PreToolUse hook.
# Blocks any Claude-authored write that contains a high-confidence live credential.
#
# Contract: reads the PreToolUse JSON on stdin; exit 0 = allow, exit 2 = block (stderr -> Claude).
# Design note: pattern list is deliberately TIGHT. We accept false negatives to get near-zero
# false positives, because a noisy guard is a guard that gets disabled.

set -uo pipefail

INPUT=$(cat)

TOOL=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null || echo "")

# Pull the content this specific tool call would actually write.
case "$TOOL" in
  Write) CONTENT=$(printf '%s' "$INPUT" | jq -r '.tool_input.content // empty' 2>/dev/null) ;;
  Edit)  CONTENT=$(printf '%s' "$INPUT" | jq -r '.tool_input.new_string // empty' 2>/dev/null) ;;
  Bash)  CONTENT=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null) ;;
  *)     exit 0 ;;
esac

[ -z "${CONTENT:-}" ] && exit 0

# High-confidence, vendor-specific credential formats only.
PATTERNS=(
  'sk-ant-[A-Za-z0-9_-]{20,}'              # Anthropic
  'sk-[A-Za-z0-9]{32,}'                    # OpenAI-style
  'ghp_[A-Za-z0-9]{36}'                    # GitHub personal access token
  'gho_[A-Za-z0-9]{36}'                    # GitHub OAuth token
  'AKIA[0-9A-Z]{16}'                       # AWS access key ID
  'AIza[0-9A-Za-z_-]{35}'                  # Google API key
  'xox[baprs]-[0-9A-Za-z-]{10,}'           # Slack
  '-----BEGIN [A-Z ]*PRIVATE KEY-----'     # PEM private key
)

for pattern in "${PATTERNS[@]}"; do
  # -e is required: some patterns start with '-' and would be parsed as grep options.
  if printf '%s' "$CONTENT" | grep -qE -e "$pattern"; then
    {
      echo "BLOCKED by secrets-guard: this ${TOOL} call contains what looks like a live credential."
      echo ""
      echo "Do not write real secrets to disk. Instead:"
      echo "  - reference an env var (os.environ[...] / process.env....), or"
      echo "  - put the value in a gitignored .env that the user populates by hand."
      echo ""
      echo "If this is a placeholder or test fixture, use an obviously fake value that does not"
      echo "match a real credential format (e.g. 'sk-ant-EXAMPLE' or '<YOUR_KEY_HERE>')."
    } >&2
    exit 2
  fi
done

exit 0
