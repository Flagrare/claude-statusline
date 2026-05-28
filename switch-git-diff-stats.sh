#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="$SCRIPT_DIR/.statusline.conf"

current=$(grep '^SHOW_GIT_DIFF_STATS=' "$CONF" 2>/dev/null | cut -d= -f2)
[ -z "$current" ] && current="false"

arg="${1:-}"
case "$arg" in
  true|on)   target="true"  ;;
  false|off) target="false" ;;
  "")
    if [ "$current" = "true" ]; then target="false"; else target="true"; fi
    ;;
  *)
    echo "Usage: switch-git-diff-stats.sh [true|on|false|off]"
    exit 1
    ;;
esac

if grep -q '^SHOW_GIT_DIFF_STATS=' "$CONF" 2>/dev/null; then
  sed -i '' "s/^SHOW_GIT_DIFF_STATS=.*/SHOW_GIT_DIFF_STATS=${target}/" "$CONF"
else
  echo "SHOW_GIT_DIFF_STATS=${target}" >> "$CONF"
fi

if [ "$target" = "true" ]; then
  echo "Git diff stats: on (+N insertions / -N deletions across staged + unstaged)"
else
  echo "Git diff stats: off"
fi
