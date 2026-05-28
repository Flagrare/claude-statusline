#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="$SCRIPT_DIR/.statusline.conf"

current=$(grep '^SHOW_PR=' "$CONF" 2>/dev/null | cut -d= -f2)
[ -z "$current" ] && current="false"

arg="${1:-}"
case "$arg" in
  true|on)   target="true"  ;;
  false|off) target="false" ;;
  "")
    if [ "$current" = "true" ]; then target="false"; else target="true"; fi
    ;;
  *)
    echo "Usage: switch-pr.sh [true|on|false|off]"
    exit 1
    ;;
esac

if grep -q '^SHOW_PR=' "$CONF" 2>/dev/null; then
  sed -i '' "s/^SHOW_PR=.*/SHOW_PR=${target}/" "$CONF"
else
  echo "SHOW_PR=${target}" >> "$CONF"
fi

if [ "$target" = "true" ]; then
  if command -v gh >/dev/null 2>&1; then
    echo "PR link: on (clickable PR number when the current branch has an open PR; requires gh)"
  else
    echo "PR link: on — but \`gh\` is not installed, so the segment will stay hidden."
    echo "  Install: https://cli.github.com/"
  fi
else
  echo "PR link: off"
fi
