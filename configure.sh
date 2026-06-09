#!/usr/bin/env bash
# Interactive feature picker for claude-statusline. Reads the current
# .statusline.conf, lets the user choose an icon mode and tick the segments
# they want, then writes the config back. Shared by /statusline-config and the
# Advanced install path. Pure POSIX-ish bash with indexed arrays only, so it
# runs on macOS's stock bash 3.2 (no associative arrays, no ${var,,}).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="$SCRIPT_DIR/.statusline.conf"
[ -f "$CONF" ] || touch "$CONF"

# Managed toggles: parallel arrays (key / label / default-when-absent).
keys=(  SHOW_GIT_DIFF_STATS SHOW_PR SHOW_WORKTREE SHOW_CONFLICTS \
        SHOW_SONNET_LIMIT SHOW_OUTPUT_STYLE SHOW_SESSION_ID SHOW_VERSION \
        SHOW_CWD SHOW_SESSION_DURATION SHOW_TOKEN_SPEED SHOW_COMPACTION \
        SHOW_EXTRA_USAGE SHOW_COST SHOW_FAST_MODE SHOW_CONTEXT_WARNING )
labels=("Git diff stats (+N -N)" "PR link" "Worktree marker" "Merge-conflicts marker" \
        "Per-model weekly usage (Sonnet/Opus)" "Output-style label" "Session ID" "Claude Code version badge" \
        "CWD path" "Session duration" "Token speed" "Compaction counter" \
        "Extra usage (overage)" "Session cost" "Fast-mode badge" "Context warning" )
defs=(  false false true true \
        false false false false \
        false false false false \
        false false true true )

conf_val() { grep "^$1=" "$CONF" 2>/dev/null | tail -1 | cut -d= -f2; }

# Seed state from the current config (falling back to defaults).
state=()
for i in "${!keys[@]}"; do
  v=$(conf_val "${keys[$i]}"); [ -z "$v" ] && v="${defs[$i]}"
  if [ "$v" = "true" ]; then state[$i]=1; else state[$i]=0; fi
done

icons=$(conf_val ICONS); [ -z "$icons" ] && icons=emoji

echo ""
echo "claude-statusline — configure"
echo ""

# --- icon mode ---
echo "Icon mode:  1) emoji   2) nerd   3) unicode   4) ascii"
printf "  choose [current: %s] > " "$icons"
read -r pick
case "$pick" in
  1) icons=emoji ;; 2) icons=nerd ;; 3) icons=unicode ;; 4) icons=ascii ;;
esac

# --- feature checklist ---
while true; do
  echo ""
  echo "Features — type numbers to toggle, then Enter to save:"
  for i in "${!keys[@]}"; do
    box="[ ]"; [ "${state[$i]}" = "1" ] && box="[x]"
    printf "  %2d) %s %s\n" "$((i+1))" "$box" "${labels[$i]}"
  done
  printf "> "
  read -r line
  [ -z "$line" ] && break
  for n in $line; do
    case "$n" in ''|*[!0-9]*) continue ;; esac
    idx=$((n-1))
    if [ "$idx" -ge 0 ] && [ "$idx" -lt "${#keys[@]}" ]; then
      if [ "${state[$idx]}" = "1" ]; then state[$idx]=0; else state[$idx]=1; fi
    fi
  done
done

# --- write config: preserve unmanaged keys, rewrite managed ones ---
managed="ICONS ${keys[*]}"
tmp=$(mktemp)
while IFS= read -r ln; do
  key=${ln%%=*}
  skip=false
  for m in $managed; do [ "$key" = "$m" ] && { skip=true; break; }; done
  [ "$skip" = true ] || printf '%s\n' "$ln"
done < "$CONF" > "$tmp"
echo "ICONS=$icons" >> "$tmp"
for i in "${!keys[@]}"; do
  v=false; [ "${state[$i]}" = "1" ] && v=true
  echo "${keys[$i]}=$v" >> "$tmp"
done
mv "$tmp" "$CONF"

# --- summary ---
on=""
for i in "${!keys[@]}"; do [ "${state[$i]}" = "1" ] && on="$on ${labels[$i]};"; done
echo ""
echo "Saved to $CONF"
echo "  icons: $icons"
echo "  on:   ${on:- (none)}"
echo "Restart Claude Code or wait for the next status-bar refresh."
