#!/usr/bin/env bash
# Toggles the Claude Code version badge (the SHOW_VERSION flag). Renamed from
# switch-version.sh in v2.7.0 — /statusline-version now reports the plugin's
# own version, so the host-app badge lives under /statusline-claude-version.
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
    echo "Usage: switch-claude-version.sh [true|on|false|off]"
    exit 1
    ;;
esac

if grep -q '^SHOW_VERSION=' "$CONF" 2>/dev/null; then
  sed -i '' "s/^SHOW_VERSION=.*/SHOW_VERSION=${target}/" "$CONF"
else
  echo "SHOW_VERSION=${target}" >> "$CONF"
fi

if [ "$target" = "true" ]; then
  echo "Claude Code version badge: on (trailing vX.Y.Z — the host app's version)"
else
  echo "Claude Code version badge: off"
fi
