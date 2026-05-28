#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="$SCRIPT_DIR/.statusline.conf"

current=$(grep '^SHOW_EXTRA_USAGE=' "$CONF" 2>/dev/null | cut -d= -f2)
[ -z "$current" ] && current="false"

arg="${1:-}"
case "$arg" in
  true|on)   target="true"  ;;
  false|off) target="false" ;;
  "")
    if [ "$current" = "true" ]; then target="false"; else target="true"; fi
    ;;
  *)
    echo "Usage: switch-extra-usage.sh [true|on|false|off]"
    exit 1
    ;;
esac

if grep -q '^SHOW_EXTRA_USAGE=' "$CONF" 2>/dev/null; then
  sed -i '' "s/^SHOW_EXTRA_USAGE=.*/SHOW_EXTRA_USAGE=${target}/" "$CONF"
else
  echo "SHOW_EXTRA_USAGE=${target}" >> "$CONF"
fi

if [ "$target" = "true" ]; then
  echo "Extra usage: on (shows pay-as-you-go overage spend when enabled on your account; auto-hides otherwise)"
else
  echo "Extra usage: off"
fi
