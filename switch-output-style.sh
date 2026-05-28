#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="$SCRIPT_DIR/.statusline.conf"

current=$(grep '^SHOW_OUTPUT_STYLE=' "$CONF" 2>/dev/null | cut -d= -f2)
[ -z "$current" ] && current="false"

arg="${1:-}"
case "$arg" in
  true|on)   target="true"  ;;
  false|off) target="false" ;;
  "")
    if [ "$current" = "true" ]; then target="false"; else target="true"; fi
    ;;
  *)
    echo "Usage: switch-output-style.sh [true|on|false|off]"
    exit 1
    ;;
esac

if grep -q '^SHOW_OUTPUT_STYLE=' "$CONF" 2>/dev/null; then
  sed -i '' "s/^SHOW_OUTPUT_STYLE=.*/SHOW_OUTPUT_STYLE=${target}/" "$CONF"
else
  echo "SHOW_OUTPUT_STYLE=${target}" >> "$CONF"
fi

if [ "$target" = "true" ]; then
  echo "Output style badge: on (shows [explanatory], [learning], etc. next to the model name)"
else
  echo "Output style badge: off"
fi
