#!/usr/bin/env bash
# Toggle the context warning, or set its token threshold.
#   on | off | true | false   → toggle visibility (SHOW_CONTEXT_WARNING)
#   <number>[k|m]              → set the threshold (e.g. 150000, 150k, 2m)
#   (no argument)              → toggle visibility
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="$SCRIPT_DIR/.statusline.conf"

set_conf() { # key value
  if grep -q "^$1=" "$CONF" 2>/dev/null; then
    sed -i '' "s/^$1=.*/$1=$2/" "$CONF"
  else
    echo "$1=$2" >> "$CONF"
  fi
}

arg="${1:-}"

# A numeric argument (optionally suffixed k/m) sets the threshold.
norm=$(printf '%s' "$arg" | tr 'A-Z' 'a-z')
mult=1; num="$norm"
case "$norm" in
  *k) mult=1000;    num=${norm%k} ;;
  *m) mult=1000000; num=${norm%m} ;;
esac
is_int=false
case "$num" in ''|*[!0-9]*) ;; *) is_int=true ;; esac

if [ -n "$arg" ] && [ "$is_int" = true ]; then
  tokens=$(( num * mult ))
  set_conf CONTEXT_WARNING_TOKENS "$tokens"
  echo "Context warning threshold set to ${tokens} tokens."
  exit 0
fi

# Otherwise treat the argument as on/off (no arg = toggle).
current=$(grep '^SHOW_CONTEXT_WARNING=' "$CONF" 2>/dev/null | cut -d= -f2)
[ -z "$current" ] && current="true"
case "$arg" in
  true|on)   target="true"  ;;
  false|off) target="false" ;;
  "")
    if [ "$current" = "true" ]; then target="false"; else target="true"; fi
    ;;
  *)
    echo "Usage: switch-context-warning.sh [on|off|<tokens, e.g. 150000 or 150k>]"
    exit 1
    ;;
esac
set_conf SHOW_CONTEXT_WARNING "$target"
if [ "$target" = "true" ]; then
  echo "Context warning: on"
else
  echo "Context warning: off"
fi
