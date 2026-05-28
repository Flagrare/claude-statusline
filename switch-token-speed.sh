#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="$SCRIPT_DIR/.statusline.conf"

current=$(grep '^SHOW_TOKEN_SPEED=' "$CONF" 2>/dev/null | cut -d= -f2)
[ -z "$current" ] && current="false"

arg="${1:-}"
case "$arg" in
  true|on)   target="true"  ;;
  false|off) target="false" ;;
  "")
    if [ "$current" = "true" ]; then target="false"; else target="true"; fi
    ;;
  *)
    echo "Usage: switch-token-speed.sh [true|on|false|off]"
    exit 1
    ;;
esac

if grep -q '^SHOW_TOKEN_SPEED=' "$CONF" 2>/dev/null; then
  sed -i '' "s/^SHOW_TOKEN_SPEED=.*/SHOW_TOKEN_SPEED=${target}/" "$CONF"
else
  echo "SHOW_TOKEN_SPEED=${target}" >> "$CONF"
fi

if [ "$target" = "true" ]; then
  echo "Token speed: on (last turn's input↓ / output↑ tokens per second)"
else
  echo "Token speed: off"
fi
