#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="$SCRIPT_DIR/.statusline.conf"

current=$(grep '^SHOW_HANDOFF=' "$CONF" 2>/dev/null | cut -d= -f2)
[ -z "$current" ] && current="true"

arg="${1:-}"
case "$arg" in
  true|on)   target="true"  ;;
  false|off) target="false" ;;
  "")
    if [ "$current" = "true" ]; then target="false"; else target="true"; fi
    ;;
  *)
    echo "Usage: switch-handoff.sh [true|on|false|off]"
    exit 1
    ;;
esac

if grep -q '^SHOW_HANDOFF=' "$CONF" 2>/dev/null; then
  sed -i '' "s/^SHOW_HANDOFF=.*/SHOW_HANDOFF=${target}/" "$CONF"
else
  echo "SHOW_HANDOFF=${target}" >> "$CONF"
fi

if [ "$target" = "true" ]; then
  echo "Handoff segment: on (shows work this session handed to another session; hidden until used)"
else
  echo "Handoff segment: off"
fi
