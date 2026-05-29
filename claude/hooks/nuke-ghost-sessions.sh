#!/bin/bash
# SessionEnd hook: auto-delete ghost sessions left behind by /clear.
# A "ghost" is a session with no meaningful user messages — just
# file-history-snapshot lines or empty content.

set -euo pipefail

INPUT=$(cat)
TRANSCRIPT_PATH=$(jq -r '.transcript_path // ""' <<< "$INPUT")

[ -z "$TRANSCRIPT_PATH" ] && exit 0
[ ! -f "$TRANSCRIPT_PATH" ] && exit 0

# Count lines that are actual user/assistant messages (not file-history-snapshot or empty)
MEANINGFUL=$(jq -r '.type // ""' "$TRANSCRIPT_PATH" 2>/dev/null \
  | grep -cvE '^(file-history-snapshot|)$' || true)

if [ "$MEANINGFUL" -gt 0 ]; then
  exit 0
fi

# This session is a ghost — nuke the JSONL
rm -f "$TRANSCRIPT_PATH"

# Also remove its subagents directory if it exists
SUBAGENTS_DIR="${TRANSCRIPT_PATH%.jsonl}/subagents"
[ -d "$SUBAGENTS_DIR" ] && rm -rf "${TRANSCRIPT_PATH%.jsonl}"

# Remove entry from sessions-index.json
SESSION_ID=$(basename "$TRANSCRIPT_PATH" .jsonl)
INDEX_FILE="$(dirname "$TRANSCRIPT_PATH")/sessions-index.json"

if [ -f "$INDEX_FILE" ]; then
  jq --arg sid "$SESSION_ID" \
    '.entries = [.entries[] | select(.sessionId != $sid)]' \
    "$INDEX_FILE" > "${INDEX_FILE}.tmp" \
    && mv "${INDEX_FILE}.tmp" "$INDEX_FILE"
fi

exit 0
