#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="$SCRIPT_DIR/.statusline.conf"

current=$(grep '^SHOW_AI_TITLE=' "$CONF" 2>/dev/null | cut -d= -f2)
[ -z "$current" ] && current="false"

arg="${1:-}"
case "$arg" in
  true|on)   target="true"  ;;
  false|off) target="false" ;;
  "")
    if [ "$current" = "true" ]; then target="false"; else target="true"; fi
    ;;
  *)
    echo "Usage: switch-ai-title.sh [true|on|false|off]"
    exit 1
    ;;
esac

if grep -q '^SHOW_AI_TITLE=' "$CONF" 2>/dev/null; then
  sed -i '' "s/^SHOW_AI_TITLE=.*/SHOW_AI_TITLE=${target}/" "$CONF"
else
  echo "SHOW_AI_TITLE=${target}" >> "$CONF"
fi

if [ "$target" = "true" ]; then
  echo "AI session title: on (humanized session name from the transcript, on row 2)"
else
  echo "AI session title: off"
fi
