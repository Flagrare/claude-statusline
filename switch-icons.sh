#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="$SCRIPT_DIR/.statusline.conf"

current=$(sed -n 's/^ICONS=//p' "$CONF" 2>/dev/null)
[ -z "$current" ] && current="emoji"

if [ -n "$1" ]; then
  target="$1"
else
  [ "$current" = "emoji" ] && target="nerd" || target="emoji"
fi

echo "ICONS=$target" > "$CONF"
echo "Switched: $current → $target"
