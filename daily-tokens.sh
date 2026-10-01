#!/usr/bin/env bash
# Sums today's token usage across every Claude Code session log (all projects,
# subagents included) and caches it for statusline.sh. Silent on every error
# path — the previous state keeps serving until the next successful run.
#
# Triggered in the background by statusline.sh when SHOW_DAILY_TOKENS=true and
# the state is missing or older than ~60s. A full day of logs can run to
# hundreds of MB, so each run only reads the bytes appended since the last one:
# the state file remembers a byte offset per log plus every API request already
# counted today.
#
# State file layout (one file, replaced atomically):
#   line 1   "<YYYY-MM-DD> <input> <output> <cache_creation> <cache_read>"
#   O<TAB><path><TAB><offset>   bytes already consumed from that log
#   S<TAB><key>                 request already counted (requestId, else message id)
# statusline.sh reads line 1 only.

export LC_ALL=C   # byte-oriented grep/awk; much faster on long lines

PROJECTS_DIR="$HOME/.claude/projects"
STATE_FILE="$HOME/.claude/.statusline-state/daily-tokens"
LOCK_DIR="${STATE_FILE}.lock"

[ -d "$PROJECTS_DIR" ] || exit 0
mkdir -p "$(dirname "$STATE_FILE")" 2>/dev/null || exit 0

# Every open session renders (and may spawn this) at once; one runner at a time.
# A lock older than 5 minutes belongs to a run that died.
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  lock_mtime=$(stat -f %m "$LOCK_DIR" 2>/dev/null || stat -c %Y "$LOCK_DIR" 2>/dev/null || echo 0)
  [ $(( $(date +%s) - lock_mtime )) -lt 300 ] && exit 0
  rm -rf "$LOCK_DIR"
  mkdir "$LOCK_DIR" 2>/dev/null || exit 0
fi
work=$(mktemp -d) || { rm -rf "$LOCK_DIR"; exit 0; }
trap 'rm -rf "$LOCK_DIR" "$work"' EXIT

today=$(date +%Y-%m-%d)
# Log timestamps are UTC ("2026-10-01T03:00:00.000Z"); local midnight in the
# same shape lets awk compare them as plain strings.
if [[ "$(uname -s)" == "Darwin" ]]; then
  midnight=$(date -j -f "%Y-%m-%d %H:%M:%S" "$today 00:00:00" +%s 2>/dev/null)
  day_start=$(date -u -r "$midnight" +%Y-%m-%dT%H:%M:%S 2>/dev/null)
else
  midnight=$(date -d "$today 00:00:00" +%s 2>/dev/null)
  day_start=$(date -u -d "@$midnight" +%Y-%m-%dT%H:%M:%S 2>/dev/null)
fi
[ -z "$day_start" ] && exit 0

# Carry today's state forward; a state file from an earlier day is dropped.
tot_in=0 tot_out=0 tot_cc=0 tot_cr=0
: > "$work/offsets"
: > "$work/seen"
if [ -f "$STATE_FILE" ]; then
  read -r st_day st_in st_out st_cc st_cr < "$STATE_FILE"
  if [ "$st_day" = "$today" ]; then
    tot_in=${st_in:-0} tot_out=${st_out:-0} tot_cc=${st_cc:-0} tot_cr=${st_cr:-0}
    grep '^O	' "$STATE_FILE" > "$work/offsets"
    grep '^S	' "$STATE_FILE" | cut -f2 > "$work/seen"
  fi
fi
: > "$work/new_offsets"

# A log not modified today can't hold today's entries.
find "$PROJECTS_DIR" -name '*.jsonl' -newermt "$today 00:00" 2>/dev/null > "$work/files"

while IFS= read -r f; do
  size=$(wc -c < "$f" 2>/dev/null | tr -d ' ')
  [ -z "$size" ] && continue
  off=$(awk -F'\t' -v p="$f" '$2 == p { print $3; exit }' "$work/offsets")
  [ -z "$off" ] && off=0
  [ "$size" -lt "$off" ] && off=0   # rewritten or truncated; the seen-set prevents recounting

  if [ "$size" -eq "$off" ]; then
    printf 'O\t%s\t%s\n' "$f" "$off" >> "$work/new_offsets"
    continue
  fi

  # The read runs to EOF, past $size if the session is still writing; anything
  # past $size is read again next run and the seen-set skips it. A line cut
  # short mid-write is safe too: it can only be counted once its trailing
  # timestamp has landed, and usage sits before that. The offset only advances
  # to $size when that byte ends a line.
  next_off=$size
  [ -n "$(tail -c +"$size" "$f" 2>/dev/null | head -c 1)" ] && next_off=$off

  # BSD tail -c and head -c move ~25 MB/s, so a first read goes straight to
  # grep; tail only handles what was appended since the last run.
  if [ "$off" -eq 0 ]; then
    reader=(cat "$f")
  else
    reader=(tail -c +"$(( off + 1 ))" "$f")
  fi
  # grep does the bulk filtering; awk is several times slower on multi-MB lines.
  read -r d_in d_out d_cc d_cr < <("${reader[@]}" 2>/dev/null \
    | grep -F '"type":"assistant"' | awk -v start="$day_start" -v seenfile="$work/seen" '
    # Top-level fields sit after the message body and raw tool inputs, which
    # can carry keys of the same name. Greedy ".*" lands the match on the last
    # occurrence; returns the offset just past it, or 0.
    function after_last(s, re) {
      return match(s, re) ? RSTART + RLENGTH : 0
    }
    function last_str(line, key,    i, rest) {
      i = after_last(line, ".*\"" key "\":\"")
      if (!i) return ""
      rest = substr(line, i)
      return substr(rest, 1, index(rest, "\"") - 1)
    }
    function extract_num(s, key,    i, rest) {
      i = index(s, "\"" key "\"")
      if (!i) return 0
      rest = substr(s, i + length(key) + 2)
      sub(/^[^0-9]*/, "", rest)
      match(rest, /^[0-9]+/)
      return (RLENGTH > 0) ? substr(rest, 1, RLENGTH) + 0 : 0
    }
    BEGIN { while ((getline k < seenfile) > 0) seen[k] = 1; close(seenfile) }
    {
      u = after_last($0, ".*\"usage\":\\{")
      if (!u) next
      ts = last_str($0, "timestamp")
      if (ts == "" || ts < start) next
      # Each content block of a reply is logged as its own line carrying the
      # same usage, so count one per API request. Lines with neither id are
      # synthetic placeholders.
      key = last_str($0, "requestId")
      if (key == "" && match($0, /"id":"msg_[A-Za-z0-9_]+"/))
        key = substr($0, RSTART + 6, RLENGTH - 7)
      if (key == "" || (key in seen)) next
      seen[key] = 1
      print key >> seenfile
      # First match after the anchor is the top-level count; iterations[]
      # repeats the same keys further along.
      usage = substr($0, u)
      d_in += extract_num(usage, "input_tokens")
      d_out += extract_num(usage, "output_tokens")
      d_cc += extract_num(usage, "cache_creation_input_tokens")
      d_cr += extract_num(usage, "cache_read_input_tokens")
    }
    END { printf "%d %d %d %d\n", d_in, d_out, d_cc, d_cr }
  ')
  tot_in=$(( tot_in + ${d_in:-0} ))
  tot_out=$(( tot_out + ${d_out:-0} ))
  tot_cc=$(( tot_cc + ${d_cc:-0} ))
  tot_cr=$(( tot_cr + ${d_cr:-0} ))
  printf 'O\t%s\t%s\n' "$f" "$next_off" >> "$work/new_offsets"
done < "$work/files"

{
  printf '%s %d %d %d %d\n' "$today" "$tot_in" "$tot_out" "$tot_cc" "$tot_cr"
  cat "$work/new_offsets"
  sed 's/^/S	/' "$work/seen"
} > "$work/state" && mv "$work/state" "$STATE_FILE"
