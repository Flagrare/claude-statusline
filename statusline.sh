#!/usr/bin/env bash
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name')

# --- context progress bar ---
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$used_pct" ]; then
  filled=$(printf "%.0f" "$(echo "$used_pct / 10" | bc -l)")
  [ "$filled" -gt 10 ] && filled=10
  empty=$(( 10 - filled ))
  bar=""
  for i in $(seq 1 "$filled"); do bar="${bar}█"; done
  for i in $(seq 1 "$empty");  do bar="${bar}░"; done
  pct_int=$(printf "%.0f" "$used_pct")
  if [ "$pct_int" -lt 50 ]; then
    color="\033[32m"   # green
  elif [ "$pct_int" -le 70 ]; then
    color="\033[33m"   # yellow
  else
    color="\033[31m"   # red
  fi
  reset="\033[0m"
  ctx=$(printf "ctx: ${color}[%s] %d%%${reset}" "$bar" "$pct_int")
else
  ctx="ctx:--"
fi

# --- rate limit color helper ---
# Usage: rate_color <pct_int>  — echoes the ANSI escape for that usage level
rate_color() {
  local pct=$1
  if [ "$pct" -lt 50 ]; then
    printf "\033[32m"   # green  — comfortable
  elif [ "$pct" -lt 70 ]; then
    printf "\033[34m"   # blue   — moderate
  elif [ "$pct" -lt 90 ]; then
    printf "\033[33m"   # yellow — getting close
  else
    printf "\033[31m"   # red    — near limit
  fi
}

# --- velocity indicator helper ---
# Usage: velocity_indicator <used_pct> <resets_at> <window_duration_secs>
# Echoes a pre-colored glyph string (color + nf-fa icon + reset), or "" (unknown).
# Glyphs (Nerd Font fa-icons, $'...' ANSI-C quoting for reliable UTF-8):
#   Burning fast → nf-fa-fire    U+F06D  $'\xef\x81\xad'  bright orange \033[38;5;208m
#   On track     → nf-fa-bolt    U+F0E7  $'\xef\x83\xa7'  cyan          \033[36m
#   Relaxed      → nf-fa-leaf    U+F06C  $'\xef\x81\xac'  bright green  \033[92m
velocity_indicator() {
  local used_pct=$1
  local resets_at=$2
  local window_dur=$3

  # Guard: missing inputs
  [ -z "$used_pct" ] || [ -z "$resets_at" ] || [ -z "$window_dur" ] && return

  local now
  now=$(date +%s)
  local remaining_secs=$(( resets_at - now ))

  # Guard: window already expired or hasn't meaningfully started
  [ "$remaining_secs" -le 0 ] && return
  [ "$remaining_secs" -ge "$window_dur" ] && return

  local elapsed_secs=$(( window_dur - remaining_secs ))

  # Guard: elapsed is too small (< 1% of window) to avoid divide-by-near-zero noise
  local min_elapsed=$(( window_dur / 100 ))
  [ "$elapsed_secs" -lt "$min_elapsed" ] && return

  # elapsed_fraction * 100, scaled by 100 for integer arithmetic (avoids bc/awk)
  # expected_pct_x100 = (elapsed_secs * 10000) / window_dur
  local expected_pct_x100=$(( elapsed_secs * 10000 / window_dur ))

  # used_pct_x100 = used_pct * 100  (used_pct is already integer)
  local used_pct_int
  used_pct_int=$(printf "%.0f" "$used_pct")
  local used_pct_x100=$(( used_pct_int * 100 ))

  # Each branch: symbol_color + glyph + reset — caller re-applies segment color after
  # Fast: used > expected * 1.25  →  used_x100 * 100 > expected_x100 * 125
  if [ $(( used_pct_x100 * 100 )) -gt $(( expected_pct_x100 * 125 )) ]; then
    local glyph=$'\xef\x81\xad'   # nf-fa-fire U+F06D
    printf " \033[38;5;208m%s\033[0m" "$glyph"
  # Relaxed: used < expected * 0.75  →  used_x100 * 100 < expected_x100 * 75
  elif [ $(( used_pct_x100 * 100 )) -lt $(( expected_pct_x100 * 75 )) ]; then
    local glyph=$'\xef\x81\xac'   # nf-fa-leaf U+F06C
    printf " \033[92m%s\033[0m" "$glyph"
  else
    local glyph=$'\xef\x83\xa7'   # nf-fa-bolt U+F0E7
    printf " \033[36m%s\033[0m" "$glyph"
  fi
}

# --- effort / thinking level ---
# Usage: effort_display <level>  — echoes pre-colored "<brain-icon> <label>" or nothing
effort_display() {
  local level=$1
  local brain=$'\xef\x86\x9d'   # nf-fa-graduation-cap U+F19D
  local color label
  case "$level" in
    low)    color="\033[38;5;244m"; label="low"    ;;
    medium) color="\033[36m";       label="medium" ;;
    high)   color="\033[32m";       label="high"   ;;
    xhigh)  color="\033[33m";       label="xhigh"  ;;
    max)    color="\033[38;5;208m"; label="max"    ;;
    *)      return ;;
  esac
  printf "${color}%s  %s\033[0m" "$brain" "$label"
}

effort_level=$(echo "$input" | jq -r '.effort.level // empty')
[ -z "$effort_level" ] && effort_level=$(jq -r '.effortLevel // empty' ~/.claude/settings.json 2>/dev/null)
effort_seg=""
if [ -n "$effort_level" ]; then
  effort_seg=$(effort_display "$effort_level")
fi

# --- rate limits ---
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_resets=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')

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
  five_pct_int=$(printf "%.0f" "$five_pct")
  five_color=$(rate_color "$five_pct_int")
  five_vel=$(velocity_indicator "$five_pct" "$five_resets" 18000)
  limit=$(printf "${five_color}5h:%.0f%%%s${five_color} [%s]\033[0m" "$five_pct" "$five_vel" "$countdown")
else
  limit=""
fi

seven_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
seven_resets=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

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
  seven_pct_int=$(printf "%.0f" "$seven_pct")
  seven_color=$(rate_color "$seven_pct_int")
  seven_vel=$(velocity_indicator "$seven_pct" "$seven_resets" 604800)
  week_limit=$(printf "${seven_color}7d:%.0f%%%s${seven_color} [%s]\033[0m" "$seven_pct" "$seven_vel" "$week_countdown")
else
  week_limit=""
fi

# --- git repo + branch ---
cwd=$(echo "$input" | jq -r '.cwd // empty')
if [ -n "$cwd" ]; then
  git_root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)
  if [ -n "$git_root" ]; then
    repo=$(basename "$git_root")
    branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null)
    [ -z "$branch" ] && branch=$(git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
    repo_icon=$'\xef\x84\x93'   # nf-fa-git U+F113
    branch_icon=$'\xee\x82\xa0' # nf-powerline-branch U+E0A0
    git_info=$(printf "\033[38;5;244m%s\033[0m %s  \033[38;5;244m%s\033[0m %s" \
      "$repo_icon" "$repo" "$branch_icon" "$branch")
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
