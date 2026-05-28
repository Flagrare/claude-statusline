#!/usr/bin/env bash
input=$(cat)

# Require jq at runtime for JSON parsing
if ! command -v jq &>/dev/null; then
  printf "statusline: jq not found"
  exit 0
fi

# Load icon config (written by install.sh)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICONS="emoji"
SHOW_COST="false"
SHOW_SONNET_LIMIT="false"
if [ -f "$SCRIPT_DIR/.statusline.conf" ]; then
  source "$SCRIPT_DIR/.statusline.conf"
fi

# ANSI color constants (actual escape chars via $'...' quoting)
CLR_GREEN=$'\033[32m'
CLR_YELLOW=$'\033[33m'
CLR_RED=$'\033[31m'
CLR_BLUE=$'\033[34m'
CLR_CYAN=$'\033[36m'
CLR_ORANGE=$'\033[38;5;208m'
CLR_GRAY=$'\033[38;5;244m'
CLR_DIM=$'\033[38;5;240m'
CLR_RESET=$'\033[0m'

# Icon definitions
if [ "$ICONS" = "nerd" ]; then
  ICON_FIRE=$'\xef\x81\xad'
  ICON_LEAF=$'\xef\x81\xac'
  ICON_BOLT=$'\xef\x83\xa7'
  ICON_BRAIN=$'\xef\x86\x9d'
  ICON_GIT=$'\xef\x84\x93'
  ICON_BRANCH=$'\xee\x82\xa0'
  ICON_AHEAD=$'\xf3\xb0\x9c\xb7'   # nf-md-arrow_up_bold   (U+F0737)
  ICON_BEHIND=$'\xf3\xb0\x9c\xae'  # nf-md-arrow_down_bold (U+F072E)
else
  ICON_FIRE="🔥"
  ICON_LEAF="🍃"
  ICON_BOLT="⚡️"
  ICON_BRAIN="🧠"
  ICON_GIT="📂"
  ICON_BRANCH="🌿"
  ICON_AHEAD="↑"
  ICON_BEHIND="↓"
fi

# Parse all values upfront in a single jq call to avoid repeated parsing
eval "$(echo "$input" | jq -r '
  @sh "model=\(.model.display_name // "unknown")",
  @sh "used_pct_raw=\(.context_window.used_percentage // "")",
  @sh "effort_level=\(.effort.level // "")",
  @sh "five_pct=\(.rate_limits.five_hour.used_percentage // "")",
  @sh "five_resets=\(.rate_limits.five_hour.resets_at // "")",
  @sh "seven_pct=\(.rate_limits.seven_day.used_percentage // "")",
  @sh "seven_resets=\(.rate_limits.seven_day.resets_at // "")",
  @sh "cwd=\(.cwd // "")"
' 2>/dev/null)" 2>/dev/null || true

# --- context progress bar ---
if [ -n "$used_pct_raw" ]; then
  pct_int=${used_pct_raw%%.*}
  [ -z "$pct_int" ] && pct_int=0
  filled=$(( pct_int / 10 ))
  [ "$filled" -gt 10 ] && filled=10
  empty=$(( 10 - filled ))
  bar=""
  for (( i=0; i<filled; i++ )); do bar="${bar}█"; done
  for (( i=0; i<empty; i++ ));  do bar="${bar}░"; done
  if [ "$pct_int" -lt 50 ]; then
    ctx_color="$CLR_GREEN"
  elif [ "$pct_int" -le 70 ]; then
    ctx_color="$CLR_YELLOW"
  else
    ctx_color="$CLR_RED"
  fi
  ctx="ctx: ${ctx_color}[${bar}] ${pct_int}%${CLR_RESET}"
else
  ctx="ctx:--"
fi

# --- rate limit color helper ---
rate_color() {
  local pct=$1
  if [ "$pct" -lt 50 ]; then
    printf "%s" "$CLR_GREEN"
  elif [ "$pct" -lt 70 ]; then
    printf "%s" "$CLR_BLUE"
  elif [ "$pct" -lt 90 ]; then
    printf "%s" "$CLR_YELLOW"
  else
    printf "%s" "$CLR_RED"
  fi
}

# --- velocity indicator ---
velocity_indicator() {
  local used_pct=$1
  local resets_at=$2
  local window_dur=$3

  [ -z "$used_pct" ] || [ -z "$resets_at" ] || [ -z "$window_dur" ] && return

  local now
  now=$(date +%s)
  local remaining_secs=$(( resets_at - now ))

  [ "$remaining_secs" -le 0 ] && return
  [ "$remaining_secs" -ge "$window_dur" ] && return

  local elapsed_secs=$(( window_dur - remaining_secs ))
  local min_elapsed=$(( window_dur / 100 ))
  [ "$elapsed_secs" -lt "$min_elapsed" ] && return

  # expected_pct_x100 = (elapsed_secs * 10000) / window_dur
  local expected_pct_x100=$(( elapsed_secs * 10000 / window_dur ))

  local used_pct_int=${used_pct%%.*}
  [ -z "$used_pct_int" ] && used_pct_int=0
  local used_pct_x100=$(( used_pct_int * 100 ))

  # Fast: used > expected * 1.25
  if [ $(( used_pct_x100 * 100 )) -gt $(( expected_pct_x100 * 125 )) ]; then
    printf " %s" "$ICON_FIRE"
  # Relaxed: used < expected * 0.75
  elif [ $(( used_pct_x100 * 100 )) -lt $(( expected_pct_x100 * 75 )) ]; then
    printf " %s" "$ICON_LEAF"
  else
    printf " %s" "$ICON_BOLT"
  fi
}

# --- effort / thinking level ---
effort_display() {
  local level=$1
  local brain="$ICON_BRAIN"
  local color label
  case "$level" in
    low)    color="$CLR_GRAY";   label="low"    ;;
    medium) color="$CLR_CYAN";   label="medium" ;;
    high)   color="$CLR_GREEN";  label="high"   ;;
    xhigh)  color="$CLR_YELLOW"; label="xhigh"  ;;
    max)    color="$CLR_ORANGE"; label="max"    ;;
    *)      return ;;
  esac
  printf "%s  %s%s%s" "$brain" "$color" "$label" "$CLR_RESET"
}

if [ -z "$effort_level" ]; then
  effort_level=$(jq -r '.effortLevel // empty' ~/.claude/settings.json 2>/dev/null)
fi
effort_seg=""
if [ -n "$effort_level" ]; then
  effort_seg=$(effort_display "$effort_level")
fi

# --- rate limit segment helpers ---
format_countdown() {
  local secs=$1 fmt=$2
  if [ "$secs" -le 0 ]; then
    printf "resetting"
    return
  fi
  if [ "$fmt" = "short" ]; then
    printf "%dh%02dm" "$(( secs / 3600 ))" "$(( (secs % 3600) / 60 ))"
  else
    local days=$(( secs / 86400 ))
    local hrs=$(( (secs % 86400) / 3600 ))
    local mins=$(( (secs % 3600) / 60 ))
    if [ "$days" -gt 0 ]; then
      printf "%dd%dh%02dm" "$days" "$hrs" "$mins"
    else
      printf "%dh%02dm" "$hrs" "$mins"
    fi
  fi
}

# Renders one rate-limit segment. Empty stdout when inputs are empty.
# $1 label  $2 used_percentage (float)  $3 resets_at (unix epoch)
# $4 window seconds  $5 countdown fmt ("short" | "long")
format_rate_segment() {
  local label=$1 pct_raw=$2 resets=$3 window=$4 fmt=$5
  [ -z "$pct_raw" ] || [ -z "$resets" ] && return

  local now remaining countdown pct_int color vel
  now=$(date +%s)
  remaining=$(( resets - now ))
  countdown=$(format_countdown "$remaining" "$fmt")
  pct_int=${pct_raw%%.*}
  [ -z "$pct_int" ] && pct_int=0
  color=$(rate_color "$pct_int")
  vel=$(velocity_indicator "$pct_raw" "$resets" "$window")

  printf "%s%s:%d%%%s%s [%s]%s" "$color" "$label" "$pct_int" "$vel" "$color" "$countdown" "$CLR_RESET"
}

# Convert ISO 8601 (with optional fractional seconds and timezone) to epoch.
# The /api/oauth/usage endpoint returns ISO; the statusline JSON returns epoch.
iso_to_epoch() {
  local ts="${1%%.*}"   # strip fractional seconds + everything after (incl. tz)
  ts="${ts%+*}"         # safety: strip +HH:MM if no fractional was present
  ts="${ts%Z}"          # safety: strip trailing Z
  if [[ "$(uname -s)" == "Darwin" ]]; then
    TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%S" "$ts" +%s 2>/dev/null
  else
    date -u -d "$ts" +%s 2>/dev/null
  fi
}

# --- rate limits (from Claude Code stdin) ---
limit=$(format_rate_segment "5h" "$five_pct"  "$five_resets"  18000  "short")
week_limit=$(format_rate_segment "7d" "$seven_pct" "$seven_resets" 604800 "long")

# --- per-model weekly limits (opt-in; from background-polled cache) ---
sonnet_limit=""
opus_limit=""
if [ "$SHOW_SONNET_LIMIT" = "true" ]; then
  CACHE_FILE="$HOME/.claude/.statusline-usage-cache.json"
  POLLER="$SCRIPT_DIR/usage-poller.sh"

  # Refresh in background when cache is missing or stale (>5 min). The current
  # render uses whatever is already in the cache — stale or absent is fine,
  # the next render picks up fresh data.
  needs_refresh=true
  if [ -f "$CACHE_FILE" ]; then
    cache_mtime=$(stat -f %m "$CACHE_FILE" 2>/dev/null || stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)
    cache_age=$(( $(date +%s) - cache_mtime ))
    [ "$cache_age" -lt 300 ] && needs_refresh=false
  fi
  if [ "$needs_refresh" = true ] && [ -x "$POLLER" ]; then
    ( "$POLLER" >/dev/null 2>&1 & ) &>/dev/null
  fi

  if [ -f "$CACHE_FILE" ]; then
    eval "$(jq -r '
      @sh "sonnet_pct=\(.seven_day_sonnet.utilization // "")",
      @sh "sonnet_iso=\(.seven_day_sonnet.resets_at // "")",
      @sh "opus_pct=\(.seven_day_opus.utilization // "")",
      @sh "opus_iso=\(.seven_day_opus.resets_at // "")"
    ' "$CACHE_FILE" 2>/dev/null)" 2>/dev/null || true

    if [ -n "$sonnet_pct" ] && [ -n "$sonnet_iso" ]; then
      sonnet_resets=$(iso_to_epoch "$sonnet_iso")
      sonnet_limit=$(format_rate_segment "sonnet" "$sonnet_pct" "$sonnet_resets" 604800 "long")
    fi
    if [ -n "$opus_pct" ] && [ -n "$opus_iso" ]; then
      opus_resets=$(iso_to_epoch "$opus_iso")
      opus_limit=$(format_rate_segment "opus" "$opus_pct" "$opus_resets" 604800 "long")
    fi
  fi
fi

# --- git repo + branch ---
git_info=""
if [ -n "$cwd" ]; then
  git_root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || true)
  if [ -n "$git_root" ]; then
    repo=$(basename "$git_root")
    branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null || echo "?")

    # Git state indicators: ~ unstaged  + staged  ? untracked
    dirty_seg=""
    git -C "$cwd" diff --quiet 2>/dev/null          || dirty_seg="${dirty_seg}${CLR_YELLOW}~${CLR_RESET}"
    git -C "$cwd" diff --cached --quiet 2>/dev/null || dirty_seg="${dirty_seg}${CLR_GREEN}+${CLR_RESET}"
    git -C "$cwd" ls-files --others --exclude-standard 2>/dev/null \
      | head -1 | grep -q . && dirty_seg="${dirty_seg}${CLR_GRAY}?${CLR_RESET}"
    [ -n "$dirty_seg" ] && dirty_seg=" ${dirty_seg}"

    # Sync indicators: prefer explicit tracking branch, fall back to origin/<branch>
    sync_seg=""
    upstream=""
    if git -C "$cwd" rev-parse --abbrev-ref '@{u}' &>/dev/null 2>&1; then
      upstream="@{u}"
    elif git -C "$cwd" rev-parse "origin/${branch}" &>/dev/null 2>&1; then
      upstream="origin/${branch}"
    fi
    if [ -n "$upstream" ]; then
      ahead=$(git -C "$cwd" rev-list --count "${upstream}..HEAD" 2>/dev/null || echo 0)
      behind=$(git -C "$cwd" rev-list --count "HEAD..${upstream}" 2>/dev/null || echo 0)
      [ "$ahead" -gt 0 ]  && sync_seg="${sync_seg} ${CLR_GREEN}${ahead}${ICON_AHEAD}${CLR_RESET}"
      [ "$behind" -gt 0 ] && sync_seg="${sync_seg} ${CLR_YELLOW}${behind}${ICON_BEHIND}${CLR_RESET}"
    fi

    git_info="${ICON_GIT} ${repo}  ${ICON_BRANCH} ${branch}${dirty_seg}${sync_seg}"
  fi
fi

# --- session cost (opt-in: set SHOW_COST=true in .statusline.conf) ---
cost_seg=""
if [ "$SHOW_COST" = "true" ] && command -v awk &>/dev/null && [ -d "$HOME/.claude/projects" ]; then
  # Derive project dir: Claude encodes cwd by replacing non-alphanumeric chars with -
  project_key=$(printf "%s" "${cwd:-$PWD}" | sed 's|[^a-zA-Z0-9-]|-|g')
  project_dir="$HOME/.claude/projects/${project_key}"
  session_file=$(ls -t "${project_dir}"/*.jsonl 2>/dev/null | head -1)
  if [ -f "$session_file" ]; then
    cost_seg=$(awk '
      function extract_num(line, key,    i, rest) {
        i = index(line, "\"" key "\"")
        if (!i) return 0
        rest = substr(line, i + length(key) + 2)
        sub(/^[^0-9]*/, "", rest)
        match(rest, /^[0-9]+/)
        return (RLENGTH > 0) ? substr(rest, 1, RLENGTH) + 0 : 0
      }
      /"type"[^"]*"assistant"/ {
        # capture model (prefer inner message.model, fall back to first match)
        n = split($0, parts, "\"model\"")
        for (k = 2; k <= n; k++) {
          sub(/^[^"]*"/, "", parts[k])
          m = substr(parts[k], 1, index(parts[k], "\"") - 1)
          if (m ~ /claude/) { mdl = m; break }
        }
        inp += extract_num($0, "input_tokens")
        out += extract_num($0, "output_tokens")
        cr  += extract_num($0, "cache_read_input_tokens")
        cc  += extract_num($0, "cache_creation_input_tokens")
      }
      END {
        if (inp + out == 0) exit
        if (index(mdl, "opus"))  { ip=15e-6; op=75e-6;  crp=1.5e-6;   ccp=18.75e-6 }
        else if (index(mdl, "haiku")) { ip=1e-6;  op=5e-6;   crp=0.1e-6;   ccp=1.25e-6  }
        else                     { ip=3e-6;  op=15e-6;  crp=0.3e-6;   ccp=3.75e-6  }
        cost = inp*ip + out*op + cr*crp + cc*ccp
        if (cost < 0.001) exit
        if (cost < 1.0) printf "$%.3f", cost
        else            printf "$%.2f",  cost
      }
    ' "$session_file" 2>/dev/null)
  fi
fi

# --- divider ---
div="  ${CLR_DIM}│${CLR_RESET}  "

# --- assemble ---
parts="$model"
[ -n "$effort_seg" ] && parts="${parts}${div}${effort_seg}"
[ -n "$git_info" ]   && parts="${parts}${div}${git_info}"
[ -n "$limit" ]        && parts="${parts}${div}${limit}"
[ -n "$week_limit" ]   && parts="${parts}${div}${week_limit}"
[ -n "$sonnet_limit" ] && parts="${parts}${div}${sonnet_limit}"
[ -n "$opus_limit" ]   && parts="${parts}${div}${opus_limit}"
[ -n "$cost_seg" ]     && parts="${parts}${div}${cost_seg}"
parts="${parts}${div}${ctx}"

printf "%s" "$parts"
