#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="$SCRIPT_DIR/.statusline.conf"

current=$(grep '^SHOW_VERSION=' "$CONF" 2>/dev/null | cut -d= -f2)
[ -z "$current" ] && current="false"

arg="${1:-}"
case "$arg" in
  true|on)   target="true"  ;;
  false|off) target="false" ;;
  "")
    if [ "$current" = "true" ]; then target="false"; else target="true"; fi
    ;;
  *)
    echo "Usage: switch-version.sh [true|on|false|off]"
    exit 1
    ;;
esac

if grep -q '^SHOW_VERSION=' "$CONF" 2>/dev/null; then
  sed -i '' "s/^SHOW_VERSION=.*/SHOW_VERSION=${target}/" "$CONF"
else
  echo "SHOW_VERSION=${target}" >> "$CONF"
fi

if [ "$target" = "true" ]; then
  echo "Claude Code version: on (trailing vX.Y.Z badge)"
else
  echo "Claude Code version: off"
fi
