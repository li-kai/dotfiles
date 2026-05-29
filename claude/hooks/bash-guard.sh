#!/bin/bash
# PreToolUse hook for the Bash tool.
# Guards: find -exec/-delete, gh api writes, python3 JSON, sensitive paths,
# curl downloads, standalone grep/cat/etc, git commit guidelines,
# shell redirect writes, cargo→just rewriting.

INPUT=$(cat)
eval "$(jq -r '@sh "CMD=\(.tool_input.command // "") SESSION_ID=\(.session_id // "unknown") TRANSCRIPT=\(.transcript_path // "")"' <<< "$INPUT")"

block() { echo "$1" >&2; exit 2; }

re='(^|[^[:alnum:]_])find([^[:alnum:]_]|$)'
if [[ $CMD =~ $re ]]; then
  re='[[:space:]]-(exec|execdir|ok)[[:space:]]|[[:space:]]-delete([^[:alnum:]_]|$)'
  if [[ $CMD =~ $re ]]; then
    block "find with -exec, -execdir, -ok, or -delete is not allowed. Use rg for content search, Glob for file discovery, or pipe find to xargs."
  fi
fi

re='(^|[;&|(])[[:space:]]*gh[[:space:]]+api([^[:alnum:]_]|$)'
if [[ $CMD =~ $re ]]; then
  shopt -s nocasematch
  re='[[:space:]](--method[[:space:]]+|-X[[:space:]]*)(POST|PUT|PATCH|DELETE)|[[:space:]]--input([^[:alnum:]_]|$)|[[:space:]]-f[[:space:]]|[[:space:]]--raw-field[[:space:]]|[[:space:]]-F[[:space:]]|[[:space:]]--field[[:space:]]'
  if [[ $CMD =~ $re ]]; then
    block "gh api write operations (POST/PUT/PATCH/DELETE/input/fields) are blocked. Only read-only (GET) calls are allowed."
  fi
  shopt -u nocasematch
fi

re='(^|[;&|(])[[:space:]]*python3?[[:space:]]+-c[[:space:]].*(^|[^[:alnum:]_])json([^[:alnum:]_]|$)'
if [[ $CMD =~ $re ]]; then
  block "Use jq instead of python3 -c for JSON manipulation in shell."
fi

SENSITIVE='\.ssh/|\.aws/|\.gnupg/|\.azure/|\.config/gcloud/|\.config/gh/|\.config/op/|\.config/age/|\.docker/config\.json|\.kube/config([ /]|$)|\.terraform\.d/|\.vault-token|\.cargo/credentials|\.sops\.yaml|\.(pem|key)([ "'"'"']|$)|[^a-zA-Z0-9](\.env|\.netrc|\.npmrc|\.pypirc)([^a-zA-Z0-9]|$)'
if [[ $CMD =~ $SENSITIVE ]]; then
  block "Access to sensitive path blocked"
fi

# Allow curl with API-interaction flags (-X, -d, -H, -F, etc.), -o/--output, pipes, or > redirect
re='(^|[;&|(])[[:space:]]*curl([^[:alnum:]_]|$)'
if [[ $CMD =~ $re ]]; then
  flags_re='[[:space:]](-X|--request|-d|--data(-raw|-binary|-urlencode)?|-H|--header|-F|--form|-u|--user|-T|--upload-file|-I|--head|-o|--output)([^[:alnum:]_]|$)'
  pipe_re='(^|[^|])\|([^|]|$)'
  redir_re='>[[:space:]]*[a-zA-Z0-9._]'
  if ! [[ $CMD =~ $flags_re ]]; then
    if ! [[ $CMD =~ $pipe_re ]] && ! [[ $CMD =~ $redir_re ]]; then
      block "Use the WebFetch or WebSearch tool instead of curl."
    fi
  fi
fi

# Show commit guidelines on first git commit per session (skip if /commit skill is active)
re='(^|[;&|(])[[:space:]]*git[[:space:]]+commit([^[:alnum:]_]|$)'
if [[ $CMD =~ $re ]]; then
  SKILL_ACTIVE=false
  if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ] && rg -q '/commit' "$TRANSCRIPT" 2>/dev/null; then
    SKILL_ACTIVE=true
  fi
  if [ "$SKILL_ACTIVE" = false ]; then
    MARKER="/tmp/claude-hook-commit-${SESSION_ID}"
    if [ ! -f "$MARKER" ]; then
      touch "$MARKER"
      SKILL_FILE="$HOME/repos/skills/skills-plugin/skills/commit/SKILL.md"
      MSG=$(sed -n '/^## Commit message format/,$p' "$SKILL_FILE" 2>/dev/null)
      if [ -n "$MSG" ]; then
        echo "$MSG" >&2
      else
        echo "Use /commit for guided commits." >&2
      fi
      exit 2
    fi
  fi
fi

# Block shell redirects to absolute or home-relative paths.
# Strip quoted strings first so > inside quotes is ignored.
if [[ $CMD == *">"* ]]; then
  if [[ $CMD == *\'* || $CMD == *\"* ]]; then
    STRIPPED=""
    q=0
    i=0
    len=${#CMD}
    while (( i < len )); do
      c="${CMD:i:1}"
      if (( q == 0 )); then
        if [[ $c == "'" ]]; then q=1
        elif [[ $c == '"' ]]; then q=2
        else STRIPPED+="$c"
        fi
      elif (( q == 1 )); then
        [[ $c == "'" ]] && q=0
      else
        if [[ $c == '\' ]]; then ((i++))
        elif [[ $c == '"' ]]; then q=0
        fi
      fi
      ((i++))
    done
  else
    STRIPPED=$CMD
  fi
  # Strip allowed redirect targets: >/dev/null variants and > /tmp/...
  re='[0-9]*>[> ]*/dev/null'
  while [[ $STRIPPED =~ $re ]]; do
    STRIPPED="${STRIPPED//"${BASH_REMATCH[0]}"/}"
  done
  re='>+[[:space:]]*/tmp/[^ ]*'
  while [[ $STRIPPED =~ $re ]]; do
    STRIPPED="${STRIPPED//"${BASH_REMATCH[0]}"/}"
  done
  re='>+[[:space:]]*[/~]'
  if [[ $STRIPPED =~ $re ]]; then
    block "Shell redirect to absolute or home path blocked. Use the Edit/Write tools for file writes."
  fi
fi

# Cargo→just rewriting is now owned by each project's .claude/settings.json.
# Projects that want it need their own PreToolUse hook.
