#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="$SCRIPT_DIR/.statusline.conf"

current=$(grep '^SHOW_CONTEXT_WARNING=' "$CONF" 2>/dev/null | cut -d= -f2)
[ -z "$current" ] && current="true"

arg="${1:-}"
case "$arg" in
  true|on)   target="true"  ;;
  false|off) target="false" ;;
  "")
    if [ "$current" = "true" ]; then target="false"; else target="true"; fi
    ;;
  *)
    echo "Usage: switch-context-warning.sh [true|on|false|off]"
    exit 1
    ;;
esac

if grep -q '^SHOW_CONTEXT_WARNING=' "$CONF" 2>/dev/null; then
  sed -i '' "s/^SHOW_CONTEXT_WARNING=.*/SHOW_CONTEXT_WARNING=${target}/" "$CONF"
else
  echo "SHOW_CONTEXT_WARNING=${target}" >> "$CONF"
fi

if [ "$target" = "true" ]; then
  echo "Context warning: on (shows ⚠ >200k once the session crosses the 200k-token threshold)"
else
  echo "Context warning: off"
fi
