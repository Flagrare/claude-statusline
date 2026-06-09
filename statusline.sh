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
SHOW_SESSION_DURATION="false"
SHOW_TOKEN_SPEED="false"
SHOW_COMPACTION="false"
SHOW_GIT_DIFF_STATS="false"
SHOW_PR="false"
SHOW_WORKTREE="true"
SHOW_CONFLICTS="true"
SHOW_OUTPUT_STYLE="false"
SHOW_SESSION_ID="false"
SHOW_VERSION="false"
SHOW_CWD="false"
SHOW_EXTRA_USAGE="false"
SHOW_FAST_MODE="true"
SHOW_CONTEXT_WARNING="true"
CONTEXT_WARNING_TOKENS="200000"
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

# Icon definitions — four modes:
#   nerd    : Nerd Font glyphs (PUA codepoints; requires terminal font set to a Nerd Font)
#   unicode : geometric Unicode symbols, all text-presentation (no emoji VS16).
#             Renders at proper monospace width in terminals that mis-size emoji
#             — e.g. Warp's default font, which scales emoji to width 1 and makes
#             them look tiny.
#   ascii   : pure 7-bit ASCII, multi-char bracketed forms for legibility. Lowest
#             common denominator — works in any terminal, including non-UTF8.
#   emoji   : default — colorful but uses emoji presentation
case "$ICONS" in
  nerd)
    ICON_FIRE=$'\xef\x81\xad'
    ICON_LEAF=$'\xef\x81\xac'
    ICON_BOLT=$'\xef\x83\xa7'
    ICON_BRAIN=$'\xef\x86\x9d'
    ICON_GIT=$'\xef\x84\x93'
    ICON_BRANCH=$'\xee\x82\xa0'
    ICON_AHEAD=$'\xf3\xb0\x9c\xb7'   # nf-md-arrow_up_bold   (U+F0737)
    ICON_BEHIND=$'\xf3\xb0\x9c\xae'  # nf-md-arrow_down_bold (U+F072E)
    ICON_CLOCK=$'\xef\x80\x97'        # nf-fa-clock_o         (U+F017)
    ICON_GAUGE=$'\xef\x83\xa4'        # nf-fa-tachometer      (U+F0E4)
    ICON_COMPACT=$'\xef\x80\xa1'      # nf-fa-refresh         (U+F021)
    ICON_WORKTREE=$'\xef\x84\xa6'     # nf-fa-code_fork       (U+F126)
    ICON_ID=$'\xef\x8b\x82'           # nf-fa-id_card         (U+F2C2)
    ICON_FAST=$'\xef\x83\xa7'         # nf-fa-bolt            (U+F0E7)
    ICON_WARN=$'\xef\x81\xb1'         # nf-fa-warning         (U+F071)
    ;;
  unicode)
    ICON_FIRE="≫"     # U+226B MUCH GREATER-THAN — burn rate exceeds expected
    ICON_LEAF="∼"     # U+223C TILDE OPERATOR    — chill, slow waves
    ICON_BOLT="≡"     # U+2261 IDENTICAL TO       — matching expected pace
    ICON_BRAIN="※"    # U+203B REFERENCE MARK     — "note this" / thinking
    ICON_GIT="◉"      # U+25C9 FISHEYE            — directory marker
    ICON_BRANCH="├"   # U+251C BOX DRAWINGS TEE   — branch off
    ICON_AHEAD="▴"    # U+25B4 SMALL UP TRIANGLE
    ICON_BEHIND="▾"   # U+25BE SMALL DOWN TRIANGLE
    ICON_CLOCK="◷"    # U+25F7 WHITE CIRCLE WITH UPPER-RIGHT QUADRANT
    ICON_GAUGE="⇶"    # U+21F6 THREE RIGHTWARDS ARROWS — speed
    ICON_COMPACT="↺"  # U+21BA ANTICLOCKWISE OPEN CIRCLE ARROW
    ICON_WORKTREE="⎇" # U+2387 ALTERNATIVE KEY SYMBOL    — linked worktree
    ICON_ID="#"       # U+0023 NUMBER SIGN              — identifier
    ICON_FAST="»"     # U+00BB RIGHT GUILLEMET          — fast-forward
    ICON_WARN="△"     # U+25B3 WHITE UP-POINTING TRIANGLE — caution
    ;;
  ascii)
    ICON_FIRE="!!"
    ICON_LEAF="~~"
    ICON_BOLT="=="
    ICON_BRAIN="[*]"
    ICON_GIT="[D]"
    ICON_BRANCH="|-"
    ICON_AHEAD="^"
    ICON_BEHIND="v"
    ICON_CLOCK="[t]"
    ICON_GAUGE="[s]"
    ICON_COMPACT="[c]"
    ICON_WORKTREE="[wt]"
    ICON_ID="[id]"
    ICON_FAST=">>"
    ICON_WARN="!"
    ;;
  *)
    ICON_FIRE="🔥"
    ICON_LEAF="🍃"
    ICON_BOLT="⚡️"
    ICON_BRAIN="🧠"
    ICON_GIT="📂"
    ICON_BRANCH="🌿"
    ICON_AHEAD="↑"
    ICON_BEHIND="↓"
    ICON_CLOCK="⏱"
    ICON_GAUGE="💨"
    ICON_COMPACT="🔄"
    ICON_WORKTREE="🌳"
    ICON_ID="🆔"
    ICON_FAST="⚡"
    ICON_WARN="⚠️"
    ;;
esac

# Parse all values upfront in a single jq call to avoid repeated parsing
eval "$(echo "$input" | jq -r '
  @sh "model=\(.model.display_name // "unknown")",
  @sh "used_pct_raw=\(.context_window.used_percentage // "")",
  @sh "effort_level=\(.effort.level // "")",
  @sh "five_pct=\(.rate_limits.five_hour.used_percentage // "")",
  @sh "five_resets=\(.rate_limits.five_hour.resets_at // "")",
  @sh "seven_pct=\(.rate_limits.seven_day.used_percentage // "")",
  @sh "seven_resets=\(.rate_limits.seven_day.resets_at // "")",
  @sh "cwd=\(.cwd // "")",
  @sh "output_style=\(.output_style.name // .output_style // .outputStyle.name // .outputStyle // "")",
  @sh "session_id=\(.session_id // .sessionId // "")",
  @sh "cc_version=\(.version // "")",
  @sh "fast_mode=\(.fast_mode // false)",
  @sh "exceeds_200k=\(.exceeds_200k_tokens // false)",
  @sh "ctx_tokens=\(.context_window.total_input_tokens // "")"
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

# --- JSONL session-derived signals ---
# Locate the active session's JSONL file. Claude Code encodes the cwd by
# replacing non-alphanumeric chars with '-' under ~/.claude/projects/.
discover_session_file() {
  local target_cwd=$1
  [ -z "$target_cwd" ] && return
  [ ! -d "$HOME/.claude/projects" ] && return
  local key dir
  key=$(printf "%s" "$target_cwd" | sed 's|[^a-zA-Z0-9-]|-|g')
  dir="$HOME/.claude/projects/${key}"
  ls -t "${dir}"/*.jsonl 2>/dev/null | head -1
}

# Single-pass parser: head -1 (session start) + tail -N (recent turns) bounds
# the scan so growing transcripts don't slow renders. Emits eval-safe shell
# assignments for first/last user/assistant timestamps and last-turn tokens.
parse_jsonl_signals() {
  local file=$1
  [ -f "$file" ] || return
  { head -n 1 "$file"; tail -n 200 "$file"; } 2>/dev/null | awk '
    function extract_str(line, key,    i, rest) {
      i = index(line, "\"" key "\":\"")
      if (!i) return ""
      rest = substr(line, i + length(key) + 4)
      return substr(rest, 1, index(rest, "\"") - 1)
    }
    function extract_num(line, key,    i, rest) {
      i = index(line, "\"" key "\"")
      if (!i) return 0
      rest = substr(line, i + length(key) + 2)
      sub(/^[^0-9]*/, "", rest)
      match(rest, /^[0-9]+/)
      return (RLENGTH > 0) ? substr(rest, 1, RLENGTH) + 0 : 0
    }
    NR == 1 { first_ts = extract_str($0, "timestamp") }
    /"type":"user"/ { pending_user_ts = extract_str($0, "timestamp") }
    /"type":"assistant"/ {
      last_user_ts = pending_user_ts
      last_asst_ts = extract_str($0, "timestamp")
      last_in = extract_num($0, "input_tokens") \
              + extract_num($0, "cache_creation_input_tokens") \
              + extract_num($0, "cache_read_input_tokens")
      last_out = extract_num($0, "output_tokens")
    }
    END {
      printf "JSONL_FIRST_TS=%s\n",    first_ts
      printf "JSONL_LAST_USER_TS=%s\n", last_user_ts
      printf "JSONL_LAST_ASST_TS=%s\n", last_asst_ts
      printf "JSONL_LAST_IN=%d\n",      last_in
      printf "JSONL_LAST_OUT=%d\n",     last_out
    }
  '
}

# Session duration: from first JSONL entry to now. Reuses format_countdown.
session_duration_segment() {
  local first_ts=$1
  [ -z "$first_ts" ] && return
  local start_epoch now elapsed
  start_epoch=$(iso_to_epoch "$first_ts")
  [ -z "$start_epoch" ] && return
  now=$(date +%s)
  elapsed=$(( now - start_epoch ))
  [ "$elapsed" -le 0 ] && return
  printf "%s %s%s%s" "$ICON_CLOCK" "$CLR_DIM" "$(format_countdown "$elapsed" "short")" "$CLR_RESET"
}

# Token speed: last assistant turn's tokens divided by its wall-clock latency.
# Renders "in/out tok/s". Skips when latency is unknown or zero.
token_speed_segment() {
  local user_ts=$1 asst_ts=$2 in_tok=$3 out_tok=$4
  [ -z "$user_ts" ] || [ -z "$asst_ts" ] && return
  local u_ep a_ep dur in_rate out_rate
  u_ep=$(iso_to_epoch "$user_ts")
  a_ep=$(iso_to_epoch "$asst_ts")
  [ -z "$u_ep" ] || [ -z "$a_ep" ] && return
  dur=$(( a_ep - u_ep ))
  [ "$dur" -le 0 ] && return
  in_rate=$(( in_tok / dur ))
  out_rate=$(( out_tok / dur ))
  printf "%s %s%d↓ %d↑/s%s" "$ICON_GAUGE" "$CLR_DIM" "$in_rate" "$out_rate" "$CLR_RESET"
}

# Compaction counter: persists last-seen context % per session. On a drop >2pp
# from a non-trivial baseline, treats it as a compaction event and increments.
# State at ~/.claude/.statusline-state/compaction-{session-id}.json.
compaction_segment() {
  local current_pct=$1 session_id=$2
  [ -z "$current_pct" ] || [ -z "$session_id" ] && return
  local state_dir="$HOME/.claude/.statusline-state"
  mkdir -p "$state_dir" 2>/dev/null || return
  local state_file="$state_dir/compaction-${session_id}.json"
  local last_pct=0 count=0
  if [ -f "$state_file" ]; then
    eval "$(jq -r '@sh "last_pct=\(.last_pct // 0) count=\(.count // 0)"' "$state_file" 2>/dev/null)" 2>/dev/null || true
  fi
  local cur_int=${current_pct%%.*}
  [ -z "$cur_int" ] && cur_int=0
  if [ "$last_pct" -gt 5 ] && [ "$cur_int" -lt $(( last_pct - 2 )) ]; then
    count=$(( count + 1 ))
  fi
  # Atomic write to avoid torn reads if multiple renders fire concurrently.
  local tmp="${state_file}.tmp"
  printf '{"last_pct":%d,"count":%d}\n' "$cur_int" "$count" > "$tmp" && mv "$tmp" "$state_file"
  [ "$count" -gt 0 ] && printf "%s%d" "$ICON_COMPACT" "$count"
}

# --- git depth helpers ---
# Aggregate insertions/deletions across staged + unstaged shortstat. Empty
# when there's nothing to show.
git_diff_stats_segment() {
  local target=$1
  local line ins=0 del=0 n
  while IFS= read -r line; do
    n=$(printf "%s" "$line" | grep -oE '[0-9]+ insertions?' | awk '{print $1}')
    [ -n "$n" ] && ins=$(( ins + n ))
    n=$(printf "%s" "$line" | grep -oE '[0-9]+ deletions?' | awk '{print $1}')
    [ -n "$n" ] && del=$(( del + n ))
  done < <(
    git -C "$target" diff --shortstat 2>/dev/null
    git -C "$target" diff --cached --shortstat 2>/dev/null
  )
  [ "$ins" -eq 0 ] && [ "$del" -eq 0 ] && return
  local out=""
  [ "$ins" -gt 0 ] && out="${CLR_GREEN}+${ins}${CLR_RESET}"
  [ "$del" -gt 0 ] && out="${out:+${out} }${CLR_RED}-${del}${CLR_RESET}"
  printf " %s" "$out"
}

# PR link for the current branch via `gh`, rendered as an OSC8 hyperlink.
# Cache-only — never blocks the render. Background-refreshes when the cache
# is stale (>60s). First render after enabling shows nothing until cache fills.
pr_link_segment() {
  local target=$1 branch=$2
  command -v gh >/dev/null 2>&1 || return
  [ -z "$branch" ] && return
  local state_dir="$HOME/.claude/.statusline-state"
  mkdir -p "$state_dir" 2>/dev/null || return
  # Sanitize branch (may contain `/`) and combine with repo basename for a unique key.
  local repo_base safe_branch cache_file
  repo_base=$(basename "$target" 2>/dev/null)
  safe_branch=${branch//\//_}
  cache_file="$state_dir/pr-${repo_base}-${safe_branch}.json"

  # Stale check: 60s TTL. On miss/stale, background-refresh and serve stale (if any).
  local fresh=false mtime
  if [ -f "$cache_file" ]; then
    mtime=$(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file" 2>/dev/null || echo 0)
    [ $(( $(date +%s) - mtime )) -lt 60 ] && fresh=true
  fi
  if [ "$fresh" != "true" ]; then
    ( cd "$target" 2>/dev/null && \
      gh pr view --json url,state,number 2>/dev/null > "${cache_file}.tmp" && \
      mv "${cache_file}.tmp" "$cache_file" ) >/dev/null 2>&1 &
    disown 2>/dev/null || true
  fi

  [ -f "$cache_file" ] || return
  local url state number
  eval "$(jq -r '@sh "url=\(.url // "") state=\(.state // "") number=\(.number // "")"' "$cache_file" 2>/dev/null)" 2>/dev/null || return
  [ -z "$number" ] && return

  local color
  case "$state" in
    OPEN)   color="$CLR_GREEN" ;;
    DRAFT)  color="$CLR_GRAY"  ;;
    MERGED) color="$CLR_CYAN"  ;;
    CLOSED) color="$CLR_RED"   ;;
    *)      color="$CLR_GRAY"  ;;
  esac
  # OSC8 hyperlink: ESC ] 8 ; ; URL BEL  TEXT  ESC ] 8 ; ; BEL
  # Whole "PR#<n>" label is the clickable link text.
  printf "  %s\033]8;;%s\007PR#%s\033]8;;\007%s" "$color" "$url" "$number" "$CLR_RESET"
}

# --- status-JSON bycatch helpers ---
# Fish-style CWD abbreviation: every dir except the last is squashed to its
# first character. $HOME → ~. Used only when no git_info renders (statusline
# already shows the repo name otherwise).
cwd_abbrev_segment() {
  local path=$1
  [ -z "$path" ] && return
  case "$path" in
    "$HOME") printf "~"; return ;;
    "$HOME"/*) path="~${path#$HOME}" ;;
  esac
  local dir last abbr
  dir=$(dirname "$path")
  last=$(basename "$path")
  if [ "$dir" = "/" ]; then printf "/%s" "$last"; return; fi
  if [ "$dir" = "~" ]; then printf "~/%s" "$last"; return; fi
  if [ "$dir" = "." ]; then printf "%s" "$last"; return; fi
  abbr=$(printf "%s" "$dir" | awk -F/ '
    {
      out = ""
      for (i = 1; i <= NF; i++) {
        seg = $i
        if (seg == "")      { out = out "/" }
        else if (seg == "~"){ out = out "~/" }
        else {
          out = out substr(seg, 1, 1)
          if (i < NF) out = out "/"
        }
      }
      print out
    }
  ')
  printf "%s/%s" "$abbr" "$last"
}

# Extra-usage / overage segment from the polled usage cache. Renders only
# when extra_usage is enabled AND has a utilization number. Format:
# "+$<credits> (<util>%)" — colored by utilization via rate_color.
extra_usage_segment() {
  local cache="$HOME/.claude/.statusline-usage-cache.json"
  [ -f "$cache" ] || return
  local enabled util credits cur
  eval "$(jq -r '
    @sh "enabled=\(.extra_usage.is_enabled // false)",
    @sh "util=\(.extra_usage.utilization // "")",
    @sh "credits=\(.extra_usage.used_credits // "")",
    @sh "cur=\(.extra_usage.currency // "")"
  ' "$cache" 2>/dev/null)" 2>/dev/null || return
  [ "$enabled" != "true" ] && return
  [ -z "$util" ] || [ "$util" = "null" ] && return
  local util_int=${util%%.*}
  [ -z "$util_int" ] && util_int=0
  local color
  color=$(rate_color "$util_int")
  local sym="\$"
  [ "$cur" = "EUR" ] && sym="€"
  if [ -n "$credits" ] && [ "$credits" != "null" ]; then
    printf "%s+%s%s (%d%%)%s" "$color" "$sym" "$credits" "$util_int" "$CLR_RESET"
  else
    printf "%sextra:%d%%%s" "$color" "$util_int" "$CLR_RESET"
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
# GIT_OPTIONAL_LOCKS=0 prevents .git/index.lock contention with concurrent
# git processes (Claude Code's own commands, editor integrations, etc.).
git_info=""
if [ -n "$cwd" ]; then
  export GIT_OPTIONAL_LOCKS=0
  git_root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || true)
  if [ -n "$git_root" ]; then
    repo=$(basename "$git_root")
    branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null || echo "?")

    # Worktree marker: swap ICON_GIT for ICON_WORKTREE when --git-dir differs
    # from --git-common-dir (i.e. we're in a linked worktree, not the main checkout).
    repo_icon="$ICON_GIT"
    if [ "$SHOW_WORKTREE" = "true" ]; then
      common_dir=$(git -C "$cwd" rev-parse --git-common-dir 2>/dev/null)
      git_dir=$(git -C "$cwd" rev-parse --git-dir 2>/dev/null)
      if [ -n "$common_dir" ] && [ -n "$git_dir" ] && [ "$common_dir" != "$git_dir" ]; then
        repo_icon="$ICON_WORKTREE"
      fi
    fi

    # Git state indicators: ~ unstaged  + staged  ? untracked  !N conflicts
    dirty_seg=""
    git -C "$cwd" diff --quiet 2>/dev/null          || dirty_seg="${dirty_seg}${CLR_YELLOW}~${CLR_RESET}"
    git -C "$cwd" diff --cached --quiet 2>/dev/null || dirty_seg="${dirty_seg}${CLR_GREEN}+${CLR_RESET}"
    git -C "$cwd" ls-files --others --exclude-standard 2>/dev/null \
      | head -1 | grep -q . && dirty_seg="${dirty_seg}${CLR_GRAY}?${CLR_RESET}"
    if [ "$SHOW_CONFLICTS" = "true" ]; then
      conflict_count=$(git -C "$cwd" diff --name-only --diff-filter=U 2>/dev/null | wc -l | tr -d ' ')
      if [ "$conflict_count" -gt 0 ]; then
        dirty_seg="${dirty_seg}${CLR_RED}!${conflict_count}${CLR_RESET}"
      fi
    fi
    [ -n "$dirty_seg" ] && dirty_seg=" ${dirty_seg}"

    # Diff stats (opt-in): +N -N totals from staged + unstaged shortstat
    stat_seg=""
    if [ "$SHOW_GIT_DIFF_STATS" = "true" ]; then
      stat_seg=$(git_diff_stats_segment "$cwd")
    fi

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

    # PR link (opt-in, cache-only background refresh)
    pr_seg=""
    if [ "$SHOW_PR" = "true" ]; then
      pr_seg=$(pr_link_segment "$git_root" "$branch")
    fi

    git_info="${repo_icon} ${repo}  ${ICON_BRANCH} ${branch}${dirty_seg}${stat_seg}${sync_seg}${pr_seg}"
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

# --- session JSONL signals (opt-in: session duration, token speed, compaction) ---
session_dur_seg=""
token_speed_seg=""
compaction_seg=""
if [ "$SHOW_SESSION_DURATION" = "true" ] || [ "$SHOW_TOKEN_SPEED" = "true" ] || [ "$SHOW_COMPACTION" = "true" ]; then
  jsonl_file=$(discover_session_file "${cwd:-$PWD}")
  if [ -f "$jsonl_file" ]; then
    # Bounded read: head -1 + tail -200 — first line carries session start,
    # last 200 lines cover the most recent turns for token-speed pairing.
    eval "$(parse_jsonl_signals "$jsonl_file" 2>/dev/null)" 2>/dev/null || true
    if [ "$SHOW_SESSION_DURATION" = "true" ]; then
      session_dur_seg=$(session_duration_segment "$JSONL_FIRST_TS")
    fi
    if [ "$SHOW_TOKEN_SPEED" = "true" ]; then
      token_speed_seg=$(token_speed_segment "$JSONL_LAST_USER_TS" "$JSONL_LAST_ASST_TS" "$JSONL_LAST_IN" "$JSONL_LAST_OUT")
    fi
    if [ "$SHOW_COMPACTION" = "true" ]; then
      compaction_seg=$(compaction_segment "$used_pct_raw" "$(basename "$jsonl_file" .jsonl)")
    fi
  fi
fi

# --- status-JSON & poller bycatch segments ---
output_style_seg=""
if [ "$SHOW_OUTPUT_STYLE" = "true" ] && [ -n "$output_style" ] && [ "$output_style" != "null" ]; then
  output_style_seg="${CLR_DIM}style:${output_style}${CLR_RESET}"
fi

session_id_seg=""
if [ "$SHOW_SESSION_ID" = "true" ] && [ -n "$session_id" ]; then
  session_id_seg="${CLR_DIM}${ICON_ID} ${session_id:0:6}${CLR_RESET}"
fi

version_seg=""
if [ "$SHOW_VERSION" = "true" ] && [ -n "$cc_version" ]; then
  version_seg="${CLR_DIM}v${cc_version}${CLR_RESET}"
fi

# CWD abbreviation: rendered alongside git_info on row 1 so the working
# directory stays visible even inside a repo (path adds context the repo
# segment alone doesn't, especially in deep subdirs).
cwd_seg=""
if [ "$SHOW_CWD" = "true" ] && [ -n "$cwd" ]; then
  cwd_seg="${ICON_GIT} ${CLR_DIM}$(cwd_abbrev_segment "$cwd")${CLR_RESET}"
fi

extra_seg=""
if [ "$SHOW_EXTRA_USAGE" = "true" ]; then
  extra_seg=$(extra_usage_segment)
fi

# Fast-mode badge: only present while Claude Code's Fast mode is active.
fast_seg=""
if [ "$SHOW_FAST_MODE" = "true" ] && [ "$fast_mode" = "true" ]; then
  fast_seg="${CLR_YELLOW}${ICON_FAST} fast${CLR_RESET}"
fi

# Humanize a token count for the warning label: 200000 → 200k, 1500000 → 1.5M.
humanize_tokens() {
  local n=$1
  if [ "$n" -ge 1000000 ] 2>/dev/null; then
    local whole=$(( n / 1000000 )) frac=$(( (n % 1000000) / 100000 ))
    if [ "$frac" -eq 0 ]; then printf "%dM" "$whole"; else printf "%d.%dM" "$whole" "$frac"; fi
  elif [ "$n" -ge 1000 ] 2>/dev/null; then
    printf "%dk" "$(( n / 1000 ))"
  else
    printf "%d" "$n"
  fi
}

# Context warning: fires when the context occupies at least CONTEXT_WARNING_TOKENS
# tokens (default 200000 — the long-context pricing tier). The label is derived
# from the threshold (>200k, >1.5M). Falls back to Claude Code's
# exceeds_200k_tokens boolean when total_input_tokens isn't provided.
ctx_warn_seg=""
if [ "$SHOW_CONTEXT_WARNING" = "true" ]; then
  warn_threshold=${CONTEXT_WARNING_TOKENS%%.*}
  case "$warn_threshold" in ''|*[!0-9]*) warn_threshold=200000 ;; esac
  if [ -n "$ctx_tokens" ] && [ "${ctx_tokens%%.*}" -ge "$warn_threshold" ] 2>/dev/null; then
    ctx_warn_seg="${CLR_RED}${ICON_WARN} >$(humanize_tokens "$warn_threshold")${CLR_RESET}"
  elif [ -z "$ctx_tokens" ] && [ "$exceeds_200k" = "true" ]; then
    ctx_warn_seg="${CLR_RED}${ICON_WARN} >200k${CLR_RESET}"
  fi
fi

# --- divider ---
div="  ${CLR_DIM}│${CLR_RESET}  "

# Display column width of a string: strip ANSI SGR + OSC8 hyperlink wrappers,
# count codepoints, then add 1 per wide emoji (2 display cols, 1 codepoint) in
# emoji mode. nerd/unicode/ascii glyphs are all single-width, so no correction.
disp_width() {
  local LC_ALL="${LC_ALL:-en_US.UTF-8}"
  local plain count e t
  plain=$(printf "%s" "$1" | sed $'s/\033\[[0-9;]*m//g; s/\033\]8;;[^\007]*\007//g')
  count=${#plain}
  if [ "$ICONS" != "nerd" ] && [ "$ICONS" != "unicode" ] && [ "$ICONS" != "ascii" ]; then
    for e in "🔥" "🍃" "🧠" "📂" "🌿" "⏱" "💨" "🔄" "🌳" "⚡" "🆔" "⚠"; do
      t=${plain//$e/}
      count=$(( count + (${#plain} - ${#t}) / ${#e} ))
    done
    # U+FE0F variation selector counts as a codepoint but renders zero-width
    t=${plain//$'\xef\xb8\x8f'/}
    count=$(( count - (${#plain} - ${#t}) ))
  fi
  printf "%s" "$count"
}

# --- terminal width (config COLS > $COLUMNS > tput > 80) ---
valid_width() { case "$1" in ''|*[!0-9]*|0) return 1 ;; *) return 0 ;; esac; }
term_width=""
for w in "$COLS" "$COLUMNS" "$(tput cols 2>/dev/null)"; do
  if valid_width "$w"; then term_width="$w"; break; fi
done
[ -z "$term_width" ] && term_width=80

# Pack non-empty segments into physical lines no wider than $1 columns, breaking
# at divider boundaries. A row too wide for the terminal wraps onto extra lines
# instead of being truncated at the edge. A single segment wider than the width
# still takes its own line — there's nothing smaller to break on.
wrap_segs() {
  local width=$1; shift
  local div_w line="" out="" seg sw lw=0
  div_w=$(disp_width "$div")
  for seg in "$@"; do
    [ -z "$seg" ] && continue
    sw=$(disp_width "$seg")
    if [ -z "$line" ]; then
      line="$seg"; lw=$sw
    elif [ $(( lw + div_w + sw )) -gt "$width" ]; then
      out="${out}${line}"$'\n'
      line="$seg"; lw=$sw
    else
      line="${line}${div}${seg}"; lw=$(( lw + div_w + sw ))
    fi
  done
  out="${out}${line}"
  printf "%s" "$out"
}

# --- assemble (flush-left rows, wrapped at terminal width) ---
# Row 1 carries the original core: identity, git+cwd, usage gauges, context.
# Row 2 carries later, optional/toggleable additions: live speed, session meta
# (output-style, session-id, version), and budget. Each row is packed into
# as many physical lines as its width needs (no truncation). Row 2 is suppressed
# entirely when none of its segments are enabled.
ctx_seg="$ctx"
[ -n "$compaction_seg" ] && ctx_seg="${ctx_seg} ${compaction_seg}"

row1=$(wrap_segs "$term_width" "$model" "$effort_seg" "$fast_seg" "$git_info" "$cwd_seg" "$limit" "$week_limit" "$sonnet_limit" "$opus_limit" "$ctx_seg" "$ctx_warn_seg")
row2=$(wrap_segs "$term_width" "$token_speed_seg" "$session_dur_seg" "$output_style_seg" "$session_id_seg" "$version_seg" "$extra_seg" "$cost_seg")

if [ -n "$row2" ]; then
  printf "%s\n%s" "$row1" "$row2"
else
  printf "%s" "$row1"
fi
