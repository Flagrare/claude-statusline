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
if [ -f "$SCRIPT_DIR/.statusline.conf" ]; then
  source "$SCRIPT_DIR/.statusline.conf"
fi

# Icon definitions
if [ "$ICONS" = "nerd" ]; then
  ICON_FIRE=$'\xef\x81\xad'
  ICON_LEAF=$'\xef\x81\xac'
  ICON_BOLT=$'\xef\x83\xa7'
  ICON_BRAIN=$'\xef\x86\x9d'
  ICON_GIT=$'\xef\x84\x93'
  ICON_BRANCH=$'\xee\x82\xa0'
  ICON_AHEAD=$'\xee\x82\xa1'   # nf-oct-arrow_up
  ICON_BEHIND=$'\xee\x82\xa2'  # nf-oct-arrow_down
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
    color="\033[32m"
  elif [ "$pct_int" -le 70 ]; then
    color="\033[33m"
  else
    color="\033[31m"
  fi
  reset="\033[0m"
  ctx=$(printf "ctx: ${color}[%s] %d%%${reset}" "$bar" "$pct_int")
else
  ctx="ctx:--"
fi

# --- rate limit color helper ---
rate_color() {
  local pct=$1
  if [ "$pct" -lt 50 ]; then
    printf "\033[32m"
  elif [ "$pct" -lt 70 ]; then
    printf "\033[34m"
  elif [ "$pct" -lt 90 ]; then
    printf "\033[33m"
  else
    printf "\033[31m"
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
    low)    color="\033[38;5;244m"; label="low"    ;;
    medium) color="\033[36m";       label="medium" ;;
    high)   color="\033[32m";       label="high"   ;;
    xhigh)  color="\033[33m";       label="xhigh"  ;;
    max)    color="\033[38;5;208m"; label="max"    ;;
    *)      return ;;
  esac
  printf "%s  ${color}%s\033[0m" "$brain" "$label"
}

if [ -z "$effort_level" ]; then
  effort_level=$(jq -r '.effortLevel // empty' ~/.claude/settings.json 2>/dev/null)
fi
effort_seg=""
if [ -n "$effort_level" ]; then
  effort_seg=$(effort_display "$effort_level")
fi

# --- rate limits ---

if [ -n "$five_pct" ] && [ -n "$five_resets" ]; then
  now=$(date +%s)
  remaining_secs=$(( five_resets - now ))
  if [ "$remaining_secs" -le 0 ]; then
    countdown="resetting"
  else
    hrs=$(( remaining_secs / 3600 ))
    mins=$(( (remaining_secs % 3600) / 60 ))
    countdown=$(printf "%dh%02dm" "$hrs" "$mins")
  fi
  five_pct_int=${five_pct%%.*}
  [ -z "$five_pct_int" ] && five_pct_int=0
  five_color=$(rate_color "$five_pct_int")
  five_vel=$(velocity_indicator "$five_pct" "$five_resets" 18000)
  limit=$(printf "${five_color}5h:%d%%%s${five_color} [%s]\033[0m" "$five_pct_int" "$five_vel" "$countdown")
else
  limit=""
fi


if [ -n "$seven_pct" ] && [ -n "$seven_resets" ]; then
  now=$(date +%s)
  remaining_secs=$(( seven_resets - now ))
  if [ "$remaining_secs" -le 0 ]; then
    week_countdown="resetting"
  else
    days=$(( remaining_secs / 86400 ))
    hrs=$(( (remaining_secs % 86400) / 3600 ))
    mins=$(( (remaining_secs % 3600) / 60 ))
    if [ "$days" -gt 0 ]; then
      week_countdown=$(printf "%dd%dh%02dm" "$days" "$hrs" "$mins")
    else
      week_countdown=$(printf "%dh%02dm" "$hrs" "$mins")
    fi
  fi
  seven_pct_int=${seven_pct%%.*}
  [ -z "$seven_pct_int" ] && seven_pct_int=0
  seven_color=$(rate_color "$seven_pct_int")
  seven_vel=$(velocity_indicator "$seven_pct" "$seven_resets" 604800)
  week_limit=$(printf "${seven_color}7d:%d%%%s${seven_color} [%s]\033[0m" "$seven_pct_int" "$seven_vel" "$week_countdown")
else
  week_limit=""
fi

# --- git repo + branch ---
git_info=""
if [ -n "$cwd" ]; then
  git_root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || true)
  if [ -n "$git_root" ]; then
    repo=$(basename "$git_root")
    branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null || echo "?")
    repo_icon="$ICON_GIT"
    branch_icon="$ICON_BRANCH"

    # Check ahead/behind relative to upstream tracking branch (no network call)
    sync_seg=""
    if git -C "$cwd" rev-parse --abbrev-ref '@{u}' &>/dev/null; then
      ahead=$(git -C "$cwd" rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)
      behind=$(git -C "$cwd" rev-list --count 'HEAD..@{u}' 2>/dev/null || echo 0)
      [ "$ahead" -gt 0 ]  && sync_seg="${sync_seg} \033[32m${ICON_AHEAD}${ahead}\033[0m"
      [ "$behind" -gt 0 ] && sync_seg="${sync_seg} \033[33m${ICON_BEHIND}${behind}\033[0m"
    fi

    git_info=$(printf "%s %s  %s %s%s" \
      "$repo_icon" "$repo" "$branch_icon" "$branch" "$sync_seg")
  fi
fi

# --- divider ---
div="  \033[38;5;240m│\033[0m  "

# --- assemble ---
parts="$model"
[ -n "$effort_seg" ] && parts=$(printf "%s${div}%s" "$parts" "$effort_seg")
[ -n "$git_info" ]   && parts=$(printf "%s${div}%s" "$parts" "$git_info")
[ -n "$limit" ]      && parts=$(printf "%s${div}%s" "$parts" "$limit")
[ -n "$week_limit" ] && parts=$(printf "%s${div}%s" "$parts" "$week_limit")
parts=$(printf "%s${div}%s" "$parts" "$ctx")

printf "%s" "$parts"
