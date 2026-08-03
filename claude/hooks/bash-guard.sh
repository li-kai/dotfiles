#!/bin/bash
# PreToolUse hook for the Bash tool.
# Guards: destructive find operations, gh API writes, Python JSON processing,
# direct pip use, sensitive paths, curl downloads, and shell redirect writes.

CMD=$(jq -r '.tool_input.command // ""')

block() { echo "$1" >&2; exit 2; }

strip_matches() {
  local variable="$1" pattern="$2" value="${!1}"
  while [[ $value =~ $pattern ]]; do
    value="${value//"${BASH_REMATCH[0]}"/}"
  done
  printf -v "$variable" '%s' "$value"
}

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

# Standardize on uv; block pip. `uv pip ...` / `uvx pip ...` stay allowed because
# pip there is preceded by uv, not by a command boundary.
re='(^|[;&|(])[[:space:]]*(sudo[[:space:]]+)?(pip|pip3)([^[:alnum:]_]|$)'
if [[ $CMD =~ $re ]]; then
  block "pip is disabled here; use uv instead (uv pip install ..., uv add ..., or uv run --with <pkg> ...)."
fi
re='(^|[^[:alnum:]_])python[0-9.]*[[:space:]]+-m[[:space:]]+pip([^[:alnum:]_]|$)'
if [[ $CMD =~ $re ]]; then
  block "python -m pip is disabled here; use uv instead (uv pip install ..., uv add ..., or uv run --with <pkg> ...)."
fi

# Exclude dotenv loader arguments and example templates from sensitive-path scanning.
SENSITIVE_CMD=$CMD
re='(^|[[:space:]])--env-file(-if-exists)?(=|[[:space:]]+)[^[:space:]]*\.env([^a-zA-Z0-9_]|$)|(^|[^a-zA-Z0-9_])\.env\.example([^a-zA-Z0-9_]|$)'
strip_matches SENSITIVE_CMD "$re"

SENSITIVE='\.ssh/|\.aws/|\.gnupg/|\.azure/|\.config/gcloud/|\.config/gh/|\.config/op/|\.config/age/|\.docker/config\.json|\.kube/config([ /]|$)|\.terraform\.d/|\.vault-token|\.cargo/credentials|\.sops\.yaml|\.(pem|key)([ "'"'"']|$)|[^a-zA-Z0-9](\.env|\.netrc|\.npmrc|\.pypirc)([^a-zA-Z0-9]|$)'
if [[ $SENSITIVE_CMD =~ $SENSITIVE ]]; then
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
  re='[0-9]*>[> ]*/dev/null|>+[[:space:]]*/tmp/[^ ]*'
  strip_matches STRIPPED "$re"
  re='>+[[:space:]]*[/~]'
  if [[ $STRIPPED =~ $re ]]; then
    block "Shell redirect to absolute or home path blocked. Use the Edit/Write tools for file writes."
  fi
fi

# Cargo-to-just rewriting is owned by each project's .claude/settings.json.
# Projects that want it need their own PreToolUse hook.
