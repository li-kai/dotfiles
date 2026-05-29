#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract model, transcript path, and context in one jq call
mapfile -t _input_fields < <(
    jq -r '
        (.transcript_path // ""),
        ((.model.display_name // .model.id // "unknown") | gsub(" *\\([^)]*\\)"; "")),
        (.context_window.used_percentage // 0 | round)' <<< "$input"
)
TRANSCRIPT="${_input_fields[0]}"
MODEL="${_input_fields[1]}"
CONTEXT_PCT="${_input_fields[2]}"

# Prefer the actual model from the transcript (reflects /model switches)
# rg pre-filters JSONL lines containing "model" before jq parses them
if [[ -n "$TRANSCRIPT" && -f "$TRANSCRIPT" ]]; then
    ACTUAL_MODEL=$(tail -c 65536 "$TRANSCRIPT" 2>/dev/null | rg '"model"' 2>/dev/null | tail -5 | jq -Rr 'try fromjson | select(.message.model) | .message.model' 2>/dev/null | tail -1)
    [[ -n "$ACTUAL_MODEL" ]] && MODEL="$ACTUAL_MODEL"
fi

# Format model: strip "claude-" prefix, version dashes to dots, title case
MODEL=$(echo "$MODEL" | sed 's/^[Cc]laude[ -]//; s/-[0-9]\{8\}$//; s/\([0-9]\)-\([0-9]\)/\1.\2/g; s/-/ /g' \
    | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2); print}')

# Color coding for context
RESET="\033[0m"
CONTEXT_COLOR="" CONTEXT_RESET=""
if (( CONTEXT_PCT >= 80 )); then
    CONTEXT_COLOR="\033[31m" CONTEXT_RESET="$RESET"
elif (( CONTEXT_PCT >= 50 )); then
    CONTEXT_COLOR="\033[33m" CONTEXT_RESET="$RESET"
fi

# ============================================================================
# Usage limits with caching
# ============================================================================
CACHE_FILE="/tmp/claude-usage-cache.json"
CACHE_TTL=300  # 5 minutes
NOW=$(date "+%s")

# Format ISO timestamp to remaining time
# Usage: format_time_remaining <timestamp> [format]
#   format: "hm" for 3h36m (default), "dh" for 1d18h
format_time_remaining() {
    local iso_timestamp="$1" format="${2:-hm}"
    [[ -z "$iso_timestamp" || "$iso_timestamp" == "null" ]] && return 1

    local reset_epoch
    reset_epoch=$(date -d "$iso_timestamp" "+%s" 2>/dev/null) || return 1

    local diff=$(( reset_epoch - NOW ))
    (( diff <= 0 )) && { echo "0m"; return 0; }

    if [[ "$format" == "dh" ]]; then
        local days=$(( diff / 86400 ))
        (( days >= 2 )) && printf "%dd" "$days" || printf "%dh" $(( diff / 3600 ))
    else
        local hours=$(( diff / 3600 ))
        (( hours > 0 )) && printf "%dh" "$hours" || printf "%dm" $(( (diff % 3600) / 60 ))
    fi
}

# Calculate fair (linear) usage percentage based on elapsed time
# Usage: get_fair_usage <timestamp> <window_minutes>
get_fair_usage() {
    local iso_timestamp="$1" window_minutes="$2"
    [[ -z "$iso_timestamp" || "$iso_timestamp" == "null" ]] && return 1

    local reset_epoch
    reset_epoch=$(date -d "$iso_timestamp" "+%s" 2>/dev/null) || return 1

    local remaining=$(( reset_epoch - NOW ))
    (( remaining < 0 )) && remaining=0

    local elapsed=$(( window_minutes - remaining / 60 ))
    (( elapsed < 0 )) && elapsed=0

    echo $(( elapsed * 100 / window_minutes ))
}

# Pace formatting: bold=ahead, italic=behind, plain=on track
pace_format() {
    local actual="$1" fair
    fair=$(get_fair_usage "$2" "$3") || { printf "%s" "$actual"; return; }
    local diff=$(( actual - fair ))
    if (( diff > 10 )); then
        printf "\033[1m%s$RESET" "$actual"
    elif (( diff < -10 )); then
        printf "\033[3m%s$RESET" "$actual"
    else
        printf "%s" "$actual"
    fi
}

# Check if cache is valid
is_cache_valid() {
    [[ -f "$CACHE_FILE" ]] || return 1
    local cache_time
    cache_time=$(date -r "$CACHE_FILE" +%s 2>/dev/null) || return 1
    (( NOW - cache_time < CACHE_TTL ))
}

# Get usage data (from cache or API)
get_usage_data() {
    if is_cache_valid; then
        cat "$CACHE_FILE"
        return 0
    fi

    local creds access_token response
    creds=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null)
    [[ -z "$creds" ]] && return 1

    access_token=$(jq -r '.claudeAiOauth.accessToken' <<< "$creds" 2>/dev/null)
    [[ -z "$access_token" || "$access_token" == "null" ]] && return 1

    response=$(curl -s --max-time 5 "https://api.anthropic.com/api/oauth/usage" \
        -H "Authorization: Bearer $access_token" \
        -H "anthropic-beta: oauth-2025-04-20" 2>/dev/null)

    if [[ -n "$response" ]] && rg -q '"five_hour"' <<< "$response"; then
        echo "$response" > "${CACHE_FILE}.tmp" && mv "${CACHE_FILE}.tmp" "$CACHE_FILE"
        echo "$response"
        return 0
    fi

    # API failed — serve stale cache if available, bump timestamp to back off
    if [[ -f "$CACHE_FILE" ]]; then
        touch "$CACHE_FILE"
        cat "$CACHE_FILE"
        return 2  # signal: stale data
    fi
    return 1
}

# Build usage info string
USAGE_INFO=""
USAGE_RESPONSE=$(get_usage_data)
USAGE_STALE=$?
USAGE_PREFIX=""; (( USAGE_STALE == 2 )) && USAGE_PREFIX=">"

if [ -n "$USAGE_RESPONSE" ]; then
    mapfile -t _usage_fields < <(
        jq -r '
            (.five_hour.utilization // ""),
            (.five_hour.resets_at // ""),
            (.seven_day.utilization // ""),
            (.seven_day.resets_at // "")' <<< "$USAGE_RESPONSE" 2>/dev/null
    )
    FIVE_HOUR="${_usage_fields[0]}"
    FIVE_HOUR_RESET="${_usage_fields[1]}"
    SEVEN_DAY="${_usage_fields[2]}"
    SEVEN_DAY_RESET="${_usage_fields[3]}"

    if [[ -n "$FIVE_HOUR" && -n "$SEVEN_DAY" ]]; then
        FIVE_HOUR_PCT=$(printf "%.0f" "$FIVE_HOUR")
        SEVEN_DAY_PCT=$(printf "%.0f" "$SEVEN_DAY")

        FIVE_HOUR_LABEL=$(format_time_remaining "$FIVE_HOUR_RESET" "hm") || FIVE_HOUR_LABEL="5h"
        SEVEN_DAY_LABEL=$(format_time_remaining "$SEVEN_DAY_RESET" "dh") || SEVEN_DAY_LABEL="7d"

        FIVE_HOUR_FMT=$(pace_format "$FIVE_HOUR_PCT" "$FIVE_HOUR_RESET" 300)
        SEVEN_DAY_FMT=$(pace_format "$SEVEN_DAY_PCT" "$SEVEN_DAY_RESET" 10080)

        USAGE_INFO=" · ${FIVE_HOUR_LABEL}: ${USAGE_PREFIX}${FIVE_HOUR_FMT}%"
        USAGE_INFO+=" ${SEVEN_DAY_LABEL}: ${USAGE_PREFIX}${SEVEN_DAY_FMT}%"
    fi
fi

# Output the status line
echo -e "$MODEL · Ctx: ${CONTEXT_COLOR}${CONTEXT_PCT}%${CONTEXT_RESET}${USAGE_INFO}"
