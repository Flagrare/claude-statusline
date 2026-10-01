#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="$SCRIPT_DIR/.statusline.conf"

current=$(grep '^SHOW_DAILY_TOKENS=' "$CONF" 2>/dev/null | cut -d= -f2)
[ -z "$current" ] && current="false"

arg="${1:-}"
case "$arg" in
  true|on)   target="true"  ;;
  false|off) target="false" ;;
  "")
    if [ "$current" = "true" ]; then target="false"; else target="true"; fi
    ;;
  *)
    echo "Usage: switch-daily-tokens.sh [true|on|false|off]"
    exit 1
    ;;
esac

if grep -q '^SHOW_DAILY_TOKENS=' "$CONF" 2>/dev/null; then
  sed -i '' "s/^SHOW_DAILY_TOKENS=.*/SHOW_DAILY_TOKENS=${target}/" "$CONF"
else
  echo "SHOW_DAILY_TOKENS=${target}" >> "$CONF"
fi

if [ "$target" = "true" ]; then
  cat <<'MSG'
Daily tokens: on (today's total across every session, e.g. "📊 297.3M today")
  What counts
    Input + output + cache writes + cache reads, for every session and
    subagent since local midnight. Cache reads usually dominate, so this is
    tokens processed, not tokens billed at the full rate.
  How it gets the data
    Reads the session logs under ~/.claude/projects/ in the background, at
    most once a minute, and only the lines added since the last read. The
    first read of the day can take a few seconds, so the segment appears on a
    later render. No network calls.
  Disable anytime
    /statusline-daily-tokens off
MSG
else
  echo "Daily tokens: off"
fi
