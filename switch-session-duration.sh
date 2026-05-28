#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="$SCRIPT_DIR/.statusline.conf"

current=$(grep '^SHOW_SESSION_DURATION=' "$CONF" 2>/dev/null | cut -d= -f2)
[ -z "$current" ] && current="false"

arg="${1:-}"
case "$arg" in
  true|on)   target="true"  ;;
  false|off) target="false" ;;
  "")
    if [ "$current" = "true" ]; then target="false"; else target="true"; fi
    ;;
  *)
    echo "Usage: switch-session-duration.sh [true|on|false|off]"
    exit 1
    ;;
esac

if grep -q '^SHOW_SESSION_DURATION=' "$CONF" 2>/dev/null; then
  sed -i '' "s/^SHOW_SESSION_DURATION=.*/SHOW_SESSION_DURATION=${target}/" "$CONF"
else
  echo "SHOW_SESSION_DURATION=${target}" >> "$CONF"
fi

if [ "$target" = "true" ]; then
  echo "Session duration: on (elapsed time since the current session started)"
else
  echo "Session duration: off"
fi
