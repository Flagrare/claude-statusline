#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="$SCRIPT_DIR/.statusline.conf"

current=$(grep '^SHOW_WORKTREE=' "$CONF" 2>/dev/null | cut -d= -f2)
[ -z "$current" ] && current="true"

arg="${1:-}"
case "$arg" in
  true|on)   target="true"  ;;
  false|off) target="false" ;;
  "")
    if [ "$current" = "true" ]; then target="false"; else target="true"; fi
    ;;
  *)
    echo "Usage: switch-worktree.sh [true|on|false|off]"
    exit 1
    ;;
esac

if grep -q '^SHOW_WORKTREE=' "$CONF" 2>/dev/null; then
  sed -i '' "s/^SHOW_WORKTREE=.*/SHOW_WORKTREE=${target}/" "$CONF"
else
  echo "SHOW_WORKTREE=${target}" >> "$CONF"
fi

if [ "$target" = "true" ]; then
  echo "Worktree marker: on (folder icon swaps when you're inside a linked worktree)"
else
  echo "Worktree marker: off (worktree checkouts render identically to the main checkout)"
fi
