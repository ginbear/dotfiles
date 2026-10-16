#!/bin/bash
# Claude Code Statusline Script (Rich version with Nerd Fonts)
# Displays: Model, Directory, Git Branch, Context Usage, Cost, Rate Limits

input=$(cat)

# ─────────────────────────────────────────────────────────────
# Nerd Fonts Icons (UTF-8 hex bytes for bash 3.x compatibility)
# ─────────────────────────────────────────────────────────────
ICON_MODEL=$(printf "\xf3\xb0\x9a\xa9")  # U+F06A9 nf-md-assistant
ICON_DIR=$(printf "\xef\x90\x93")        # U+F413 nf-oct-file_directory
ICON_GIT=$(printf "\xee\x82\xa0")        # U+E0A0 nf-dev-git_branch
ICON_CONTEXT=$(printf "\xef\x83\xa4")    # U+F0E4 nf-fa-tachometer
ICON_RATE=$(printf "\xef\x80\x97")       # U+F017 nf-fa-clock_o

# ─────────────────────────────────────────────────────────────
# Extract values using jq
# ─────────────────────────────────────────────────────────────
MODEL=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
CURRENT_DIR=$(echo "$input" | jq -r '.workspace.current_dir // "/"')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')

# Context window usage
CTX_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
USAGE=$(echo "$input" | jq '.context_window.current_usage // empty')

# Rate limits (Pro/Max subscribers only)
FIVE_H_PCT=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
FIVE_H_RESET=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
SEVEN_D_PCT=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
SEVEN_D_RESET=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# ─────────────────────────────────────────────────────────────
# Format directory (show last component)
# ─────────────────────────────────────────────────────────────
DIR_NAME="${CURRENT_DIR##*/}"
[ -z "$DIR_NAME" ] && DIR_NAME="/"

# ─────────────────────────────────────────────────────────────
# Git branch
# ─────────────────────────────────────────────────────────────
GIT_BRANCH=""
if git -C "$CURRENT_DIR" rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git -C "$CURRENT_DIR" branch --show-current 2>/dev/null)
    if [ -n "$BRANCH" ]; then
        GIT_BRANCH=" ${ICON_GIT} ${BRANCH}"
    fi
fi

# ─────────────────────────────────────────────────────────────
# Context usage: absolute value with warning thresholds
# Resuming a large session after cache expiry (5min TTL)
# consumes rate limits proportional to context size.
# ─────────────────────────────────────────────────────────────
CTX_WARN_THRESHOLD=150000   # ⚠ consider /compact before stepping away
CTX_CRIT_THRESHOLD=300000   # 🔴 strongly consider /compact or new session

ICON_WARN=$(printf "\xef\x81\xb1")    # U+F071 nf-fa-exclamation_triangle
ICON_CRIT=$(printf "\xef\x81\xaa")    # U+F06A nf-fa-exclamation_circle

format_tokens() {
    local tokens=$1
    if [ "$tokens" -ge 1000000 ]; then
        local m=$((tokens / 1000000))
        local remainder=$(( (tokens % 1000000) / 100000 ))
        if [ "$remainder" -eq 0 ]; then
            echo "${m}M"
        else
            echo "${m}.${remainder}M"
        fi
    elif [ "$tokens" -ge 1000 ]; then
        echo "$((tokens / 1000))k"
    else
        echo "${tokens}"
    fi
}

# ─────────────────────────────────────────────────────────────
# Format cost
# ─────────────────────────────────────────────────────────────
if [ "$COST" = "0" ] || [ "$COST" = "null" ]; then
    COST_STR="0.00"
else
    COST_STR=$(echo "$COST" | awk '{
        if ($1 < 0.01) {
            printf "%.4f", $1
        } else {
            printf "%.2f", $1
        }
    }')
fi

if [ -n "$USAGE" ] && [ "$USAGE" != "null" ]; then
    TOKENS=$(echo "$USAGE" | jq '(.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0)')
else
    TOKENS=0
fi

TOKENS_FMT=$(format_tokens "$TOKENS")
CTX_SIZE_FMT=$(format_tokens "$CTX_SIZE")

CLR_YELLOW=$(printf '\033[33m')
CLR_RED=$(printf '\033[31m')
CLR_RESET=$(printf '\033[0m')

if [ "$TOKENS" -ge "$CTX_CRIT_THRESHOLD" ]; then
    CTX_STR="${CLR_RED}${ICON_CRIT} ${TOKENS_FMT}(\$${COST_STR})/${CTX_SIZE_FMT}${CLR_RESET}"
elif [ "$TOKENS" -ge "$CTX_WARN_THRESHOLD" ]; then
    CTX_STR="${CLR_YELLOW}${ICON_WARN} ${TOKENS_FMT}(\$${COST_STR})/${CTX_SIZE_FMT}${CLR_RESET}"
else
    CTX_STR="${ICON_CONTEXT} ${TOKENS_FMT}(\$${COST_STR})/${CTX_SIZE_FMT}"
fi

# ─────────────────────────────────────────────────────────────
# Format rate limits with reset time
# ─────────────────────────────────────────────────────────────
format_reset() {
    local reset_at=$1
    if [ -z "$reset_at" ] || [ "$reset_at" = "null" ]; then
        return
    fi
    local now
    now=$(date +%s)
    local diff=$((reset_at - now))
    if [ $diff -le 0 ]; then
        echo "now"
        return
    fi
    local hours=$((diff / 3600))
    local mins=$(( (diff % 3600) / 60 ))
    if [ $hours -gt 0 ]; then
        echo "${hours}h${mins}m"
    else
        echo "${mins}m"
    fi
}

RATE_STR=""
if [ -n "$FIVE_H_PCT" ]; then
    FIVE_H_FMT=$(printf '%.0f' "$FIVE_H_PCT")
    FIVE_H_RESET_FMT=$(format_reset "$FIVE_H_RESET")
    RATE_STR="5h:${FIVE_H_FMT}%"
    [ -n "$FIVE_H_RESET_FMT" ] && RATE_STR="${RATE_STR}(${FIVE_H_RESET_FMT})"
fi
if [ -n "$SEVEN_D_PCT" ]; then
    SEVEN_D_FMT=$(printf '%.0f' "$SEVEN_D_PCT")
    SEVEN_D_RESET_FMT=$(format_reset "$SEVEN_D_RESET")
    [ -n "$RATE_STR" ] && RATE_STR="${RATE_STR} "
    RATE_STR="${RATE_STR}7d:${SEVEN_D_FMT}%"
    [ -n "$SEVEN_D_RESET_FMT" ] && RATE_STR="${RATE_STR}(${SEVEN_D_RESET_FMT})"
fi

# ─────────────────────────────────────────────────────────────
# Prompt cache: time left until the cached prefix goes cold
# ─────────────────────────────────────────────────────────────
ICON_CACHE=$(printf "\xef\x83\xa7")   # U+F0E7 nf-fa-bolt
ICON_COLD=$(printf "\xef\x8b\x9c")    # U+F2DC nf-fa-snowflake_o

CACHE_STR=""
CACHE_WARM=$(echo "$input" | jq -r '.prompt_cache.warm')
if [ "$CACHE_WARM" = "true" ]; then
    CACHE_EXP=$(echo "$input" | jq -r '.prompt_cache.expires_at // 0 | floor')
    CACHE_TTL=$(echo "$input" | jq -r '.prompt_cache.ttl // "?"')
    CACHE_STR="${ICON_CACHE} $(format_reset "$CACHE_EXP")/${CACHE_TTL}"
    [ $((CACHE_EXP - $(date +%s))) -lt 300 ] && CACHE_STR="${CLR_YELLOW}${CACHE_STR}${CLR_RESET}"
elif [ "$CACHE_WARM" = "false" ]; then
    RECACHE=$(echo "$input" | jq -r '.prompt_cache.recache_tokens_if_cold // 0')
    CACHE_STR="${ICON_COLD} cold"
    [ "$RECACHE" -gt 0 ] && CACHE_STR="${CACHE_STR}(+$(format_tokens "$RECACHE"))"
fi

# ─────────────────────────────────────────────────────────────
# AWS: time left on each SSO profile's cached role credentials
# Commands run on these cached role credentials until they expire; the SSO
# access token beside them lasts only ~1h and is not what a command checks first.
# Profiles come from ~/.claude/statusline-aws-profiles ("<label> <profile>" per line).
# ─────────────────────────────────────────────────────────────
ICON_AWS=$(printf "\xef\x83\x82")     # U+F0C2 nf-fa-cloud

aws_creds_expiry() {
    local profile=$1 account role session key file
    read -r account role session < <(awk -v p="[profile ${profile}]" '
        /^\[/ { inside = ($0 == p) }
        inside && $1 == "sso_account_id" { a = $3 }
        inside && $1 == "sso_role_name"  { r = $3 }
        inside && $1 == "sso_session"    { s = $3 }
        END { print a, r, s }' ~/.aws/config 2>/dev/null)
    [ -z "$role" ] && return
    # Same key the AWS CLI derives for its SSO credential cache.
    key=$(printf '{"accountId":"%s","roleName":"%s","sessionName":"%s"}' "$account" "$role" "$session" | shasum | cut -c1-40)
    file="$HOME/.aws/cli/cache/${key}.json"
    [ -f "$file" ] && jq -r '.Credentials.Expiration | sub("\\+00:00$"; "Z") | fromdateiso8601' "$file" 2>/dev/null
}

AWS_STR=""
AWS_PROFILES_FILE="$HOME/.claude/statusline-aws-profiles"
if [ -f "$AWS_PROFILES_FILE" ]; then
    NOW=$(date +%s)
    while read -r label profile; do
        [ -z "$profile" ] && continue
        EXP=$(aws_creds_expiry "$profile")
        if [ -z "$EXP" ] || [ "$EXP" -le "$NOW" ]; then
            ITEM="${CLR_RED}${label}:expired${CLR_RESET}"
        elif [ $((EXP - NOW)) -lt 1800 ]; then
            ITEM="${CLR_YELLOW}${label}:$(format_reset "$EXP")${CLR_RESET}"
        else
            ITEM="${label}:$(format_reset "$EXP")"
        fi
        AWS_STR="${AWS_STR:+${AWS_STR} }${ITEM}"
    done < "$AWS_PROFILES_FILE"
fi

# ─────────────────────────────────────────────────────────────
# Output
# ─────────────────────────────────────────────────────────────
OUTPUT="${ICON_MODEL} ${MODEL}  ${ICON_DIR} ${DIR_NAME}${GIT_BRANCH}  ${CTX_STR}"
[ -n "$CACHE_STR" ] && OUTPUT="${OUTPUT}  ${CACHE_STR}"
[ -n "$RATE_STR" ] && OUTPUT="${OUTPUT}  ${ICON_RATE} ${RATE_STR}"
[ -n "$AWS_STR" ] && OUTPUT="${OUTPUT}  ${ICON_AWS} ${AWS_STR}"
echo "$OUTPUT"
