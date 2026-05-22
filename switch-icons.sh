#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="$SCRIPT_DIR/.statusline.conf"

current=$(sed -n 's/^ICONS=//p' "$CONF" 2>/dev/null)
[ -z "$current" ] && current="emoji"

if [ -n "$1" ]; then
  case "$1" in
    emoji|nerd) target="$1" ;;
    *) echo "Unknown mode: $1 (valid: emoji, nerd)"; exit 1 ;;
  esac
else
  [ "$current" = "emoji" ] && target="nerd" || target="emoji"
fi

echo "ICONS=$target" > "$CONF"
echo "Switched: $current → $target"
