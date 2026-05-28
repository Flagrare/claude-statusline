#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="$SCRIPT_DIR/.statusline.conf"

current=$(grep '^SHOW_CONFLICTS=' "$CONF" 2>/dev/null | cut -d= -f2)
[ -z "$current" ] && current="true"

arg="${1:-}"
case "$arg" in
  true|on)   target="true"  ;;
  false|off) target="false" ;;
  "")
    if [ "$current" = "true" ]; then target="false"; else target="true"; fi
    ;;
  *)
    echo "Usage: switch-conflicts.sh [true|on|false|off]"
    exit 1
    ;;
esac

if grep -q '^SHOW_CONFLICTS=' "$CONF" 2>/dev/null; then
  sed -i '' "s/^SHOW_CONFLICTS=.*/SHOW_CONFLICTS=${target}/" "$CONF"
else
  echo "SHOW_CONFLICTS=${target}" >> "$CONF"
fi

if [ "$target" = "true" ]; then
  echo "Conflicts marker: on (shows !N in red when there are unresolved merge conflicts)"
else
  echo "Conflicts marker: off"
fi
