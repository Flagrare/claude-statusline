#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="$SCRIPT_DIR/.statusline.conf"

current=$(grep '^SHOW_LOOP=' "$CONF" 2>/dev/null | cut -d= -f2)
[ -z "$current" ] && current="true"

arg="${1:-}"
case "$arg" in
  true|on)   target="true"  ;;
  false|off) target="false" ;;
  "")
    if [ "$current" = "true" ]; then target="false"; else target="true"; fi
    ;;
  *)
    echo "Usage: switch-loop.sh [true|on|false|off]"
    exit 1
    ;;
esac

if grep -q '^SHOW_LOOP=' "$CONF" 2>/dev/null; then
  sed -i '' "s/^SHOW_LOOP=.*/SHOW_LOOP=${target}/" "$CONF"
else
  echo "SHOW_LOOP=${target}" >> "$CONF"
fi

if [ "$target" = "true" ]; then
  echo "/loop indicator: on (renders schedule on row 1 while a /loop cron is active)"
else
  echo "/loop indicator: off"
fi
