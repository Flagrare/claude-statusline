#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="$SCRIPT_DIR/.statusline.conf"

current=$(grep '^SHOW_COMPACTION=' "$CONF" 2>/dev/null | cut -d= -f2)
[ -z "$current" ] && current="false"

arg="${1:-}"
case "$arg" in
  true|on)   target="true"  ;;
  false|off) target="false" ;;
  "")
    if [ "$current" = "true" ]; then target="false"; else target="true"; fi
    ;;
  *)
    echo "Usage: switch-compaction.sh [true|on|false|off]"
    exit 1
    ;;
esac

if grep -q '^SHOW_COMPACTION=' "$CONF" 2>/dev/null; then
  sed -i '' "s/^SHOW_COMPACTION=.*/SHOW_COMPACTION=${target}/" "$CONF"
else
  echo "SHOW_COMPACTION=${target}" >> "$CONF"
fi

if [ "$target" = "true" ]; then
  echo "Compaction counter: on (counts auto-compaction events in the current session)"
else
  echo "Compaction counter: off"
fi
