#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="$SCRIPT_DIR/.statusline.conf"

current=$(grep '^SHOW_FAST_MODE=' "$CONF" 2>/dev/null | cut -d= -f2)
[ -z "$current" ] && current="true"

arg="${1:-}"
case "$arg" in
  true|on)   target="true"  ;;
  false|off) target="false" ;;
  "")
    if [ "$current" = "true" ]; then target="false"; else target="true"; fi
    ;;
  *)
    echo "Usage: switch-fast-mode.sh [true|on|false|off]"
    exit 1
    ;;
esac

if grep -q '^SHOW_FAST_MODE=' "$CONF" 2>/dev/null; then
  sed -i '' "s/^SHOW_FAST_MODE=.*/SHOW_FAST_MODE=${target}/" "$CONF"
else
  echo "SHOW_FAST_MODE=${target}" >> "$CONF"
fi

if [ "$target" = "true" ]; then
  echo "Fast-mode badge: on (shows a ⚡ fast badge while Claude Code Fast mode is active)"
else
  echo "Fast-mode badge: off"
fi
