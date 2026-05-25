#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="$SCRIPT_DIR/.statusline.conf"

current=$(grep '^ICONS=' "$CONF" 2>/dev/null | cut -d= -f2)
[ -z "$current" ] && current="emoji"

if [ -n "$1" ]; then
  case "$1" in
    emoji|nerd) target="$1" ;;
    *) echo "Unknown mode: $1 (valid: emoji, nerd)"; exit 1 ;;
  esac
else
  [ "$current" = "emoji" ] && target="nerd" || target="emoji"
fi

if grep -q '^ICONS=' "$CONF" 2>/dev/null; then
  sed -i '' "s/^ICONS=.*/ICONS=${target}/" "$CONF"
else
  echo "ICONS=${target}" >> "$CONF"
fi

echo "Switched: $current → $target"
