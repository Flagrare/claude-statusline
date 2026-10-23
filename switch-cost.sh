#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="$SCRIPT_DIR/.statusline.conf"

# Read current value (default false)
current=$(grep '^SHOW_COST=' "$CONF" 2>/dev/null | cut -d= -f2)
[ -z "$current" ] && current="false"

# Determine target
arg="${1:-}"
case "$arg" in
  true|on)   target="true"  ;;
  false|off) target="false" ;;
  "")
    if [ "$current" = "true" ]; then target="false"; else target="true"; fi
    ;;
  *)
    echo "Usage: switch-cost.sh [true|on|false|off]"
    exit 1
    ;;
esac

# Write back
if grep -q '^SHOW_COST=' "$CONF" 2>/dev/null; then
  # Portable in-place edit (matches the mktemp pattern in install/update/uninstall).
  # `sed -i ''` is BSD/macOS-only; on GNU sed (Linux/WSL) the '' is read as the
  # script and $CONF as a second input file, so the write silently fails.
  tmp=$(mktemp)
  sed "s/^SHOW_COST=.*/SHOW_COST=${target}/" "$CONF" > "$tmp"
  mv "$tmp" "$CONF"
else
  echo "SHOW_COST=${target}" >> "$CONF"
fi

if [ "$target" = "true" ]; then
  echo "Session cost tracking: on (API plan users only — estimated spend will appear in the status bar)"
else
  echo "Session cost tracking: off"
fi
