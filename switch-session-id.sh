#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="$SCRIPT_DIR/.statusline.conf"

current=$(grep '^SHOW_SESSION_ID=' "$CONF" 2>/dev/null | cut -d= -f2)
[ -z "$current" ] && current="false"

arg="${1:-}"
case "$arg" in
  true|on)   target="true"  ;;
  false|off) target="false" ;;
  "")
    if [ "$current" = "true" ]; then target="false"; else target="true"; fi
    ;;
  *)
    echo "Usage: switch-session-id.sh [true|on|false|off]"
    exit 1
    ;;
esac

if grep -q '^SHOW_SESSION_ID=' "$CONF" 2>/dev/null; then
  sed -i '' "s/^SHOW_SESSION_ID=.*/SHOW_SESSION_ID=${target}/" "$CONF"
else
  echo "SHOW_SESSION_ID=${target}" >> "$CONF"
fi

if [ "$target" = "true" ]; then
  echo "Session ID: on (trailing 6-char prefix of the current session UUID)"
else
  echo "Session ID: off"
fi
