#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="$SCRIPT_DIR/.statusline.conf"

current=$(grep '^SHOW_GOAL=' "$CONF" 2>/dev/null | cut -d= -f2)
[ -z "$current" ] && current="true"

arg="${1:-}"
case "$arg" in
  true|on)   target="true"  ;;
  false|off) target="false" ;;
  "")
    if [ "$current" = "true" ]; then target="false"; else target="true"; fi
    ;;
  *)
    echo "Usage: switch-goal.sh [true|on|false|off]"
    exit 1
    ;;
esac

if grep -q '^SHOW_GOAL=' "$CONF" 2>/dev/null; then
  sed -i '' "s/^SHOW_GOAL=.*/SHOW_GOAL=${target}/" "$CONF"
else
  echo "SHOW_GOAL=${target}" >> "$CONF"
fi

if [ "$target" = "true" ]; then
  echo "/goal indicator: on (renders the active condition on row 1 while a goal is running)"
else
  echo "/goal indicator: off"
fi
