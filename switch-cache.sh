#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="$SCRIPT_DIR/.statusline.conf"

current=$(grep '^SHOW_CACHE=' "$CONF" 2>/dev/null | cut -d= -f2)
[ -z "$current" ] && current="false"

arg="${1:-}"
case "$arg" in
  true|on)   target="true"  ;;
  false|off) target="false" ;;
  "")
    if [ "$current" = "true" ]; then target="false"; else target="true"; fi
    ;;
  *)
    echo "Usage: switch-cache.sh [true|on|false|off]"
    exit 1
    ;;
esac

if grep -q '^SHOW_CACHE=' "$CONF" 2>/dev/null; then
  sed -i '' "s/^SHOW_CACHE=.*/SHOW_CACHE=${target}/" "$CONF"
else
  echo "SHOW_CACHE=${target}" >> "$CONF"
fi

if [ "$target" = "true" ]; then
  echo "Prompt cache: on (hit ratio, and how long until the cache goes cold)"
else
  echo "Prompt cache: off"
fi
