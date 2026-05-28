#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="$SCRIPT_DIR/.statusline.conf"

current=$(grep '^SHOW_CWD=' "$CONF" 2>/dev/null | cut -d= -f2)
[ -z "$current" ] && current="false"

arg="${1:-}"
case "$arg" in
  true|on)   target="true"  ;;
  false|off) target="false" ;;
  "")
    if [ "$current" = "true" ]; then target="false"; else target="true"; fi
    ;;
  *)
    echo "Usage: switch-cwd.sh [true|on|false|off]"
    exit 1
    ;;
esac

if grep -q '^SHOW_CWD=' "$CONF" 2>/dev/null; then
  sed -i '' "s/^SHOW_CWD=.*/SHOW_CWD=${target}/" "$CONF"
else
  echo "SHOW_CWD=${target}" >> "$CONF"
fi

if [ "$target" = "true" ]; then
  echo "CWD display: on (fish-style abbreviated path when you're outside any git repo)"
else
  echo "CWD display: off"
fi
