#!/usr/bin/env bash
# Interactive feature picker for claude-statusline. Reads the current
# .statusline.conf, lets the user choose an icon mode and tick the segments
# they want, then writes the config back. Shared by /statusline-config and the
# Advanced install path.
#
# Two UX paths:
#   1. gum (charmbracelet/gum) — proper arrow/space checkbox UI when installed.
#   2. Numbered-loop fallback — pure POSIX-ish bash, runs anywhere including
#      macOS's stock bash 3.2 (no associative arrays, no ${var,,}).
#
# When gum is missing we offer to install it on first run (one prompt, never
# again — declining drops to the fallback for this and future invocations).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="$SCRIPT_DIR/.statusline.conf"
[ -f "$CONF" ] || touch "$CONF"

# Managed toggles: parallel arrays (key / label / default-when-absent).
keys=(  SHOW_GIT_DIFF_STATS SHOW_PR SHOW_WORKTREE SHOW_CONFLICTS \
        SHOW_SONNET_LIMIT SHOW_OUTPUT_STYLE SHOW_SESSION_ID SHOW_VERSION \
        SHOW_CWD SHOW_SESSION_DURATION SHOW_TOKEN_SPEED SHOW_COMPACTION \
        SHOW_EXTRA_USAGE SHOW_COST SHOW_FAST_MODE SHOW_CONTEXT_WARNING \
        SHOW_AI_TITLE SHOW_GOAL SHOW_LOOP )
labels=("Git diff stats (+N -N)" "PR link" "Worktree marker" "Merge-conflicts marker" \
        "Per-model weekly usage (Sonnet/Opus)" "Output-style label" "Session ID" "Claude Code version badge" \
        "CWD path" "Session duration" "Token speed" "Compaction counter" \
        "Extra usage (overage)" "Session cost" "Fast-mode badge" "Context warning" \
        "AI session title" "/goal indicator" "/loop indicator" )
defs=(  false false true true \
        false false false false \
        false false false false \
        false false true true \
        false true true )

conf_val() { grep "^$1=" "$CONF" 2>/dev/null | tail -1 | cut -d= -f2; }

# Seed state from the current config (falling back to defaults).
state=()
for i in "${!keys[@]}"; do
  v=$(conf_val "${keys[$i]}"); [ -z "$v" ] && v="${defs[$i]}"
  if [ "$v" = "true" ]; then state[$i]=1; else state[$i]=0; fi
done

icons=$(conf_val ICONS); [ -z "$icons" ] && icons=emoji

# --- gum availability + soft-install prompt ---
# A sentinel file remembers a prior decline so we don't pester on every run.
GUM_DECLINED="$SCRIPT_DIR/.gum-declined"

offer_gum_install() {
  # Already installed? Nothing to do.
  command -v gum >/dev/null 2>&1 && return 0
  # User declined previously? Stay declined.
  [ -f "$GUM_DECLINED" ] && return 1

  local pm install_cmd
  if command -v brew >/dev/null 2>&1; then
    pm=brew; install_cmd="brew install gum"
  elif command -v apt-get >/dev/null 2>&1; then
    pm=apt; install_cmd="sudo apt-get install -y gum"
  elif command -v pacman >/dev/null 2>&1; then
    pm=pacman; install_cmd="sudo pacman -S --noconfirm gum"
  else
    return 1
  fi

  printf "\nclaude-statusline supports an arrow-key checkbox UI when 'gum' is installed.\n"
  printf "  Install command: %s\n" "$install_cmd"
  printf "  Install gum now? [y/N] "
  read -r answer
  case "$answer" in
    [yY]*)
      if eval "$install_cmd" >/dev/null 2>&1; then
        command -v gum >/dev/null 2>&1 && return 0
      fi
      echo "  gum install failed; falling back to numbered checklist."
      return 1
      ;;
    *)
      touch "$GUM_DECLINED" 2>/dev/null
      echo "  Skipped. Re-run with 'rm $GUM_DECLINED' to be asked again."
      return 1
      ;;
  esac
}

# --- gum-driven configurator ---
configure_with_gum() {
  echo ""
  echo "claude-statusline — configure"
  echo ""

  local picked
  picked=$(printf "emoji\nnerd\nunicode\nascii\n" | gum choose \
    --header "Icon mode (enter to confirm)" \
    --selected "$icons") || return 1
  [ -n "$picked" ] && icons=$picked

  # Build the input lines (one label per line) and the comma-separated
  # currently-selected list for --selected.
  local input="" selected="" first=1
  for i in "${!keys[@]}"; do
    [ "$first" = 1 ] && first=0 || input="${input}"$'\n'
    input="${input}${labels[$i]}"
    if [ "${state[$i]}" = "1" ]; then
      [ -z "$selected" ] && selected="${labels[$i]}" || selected="${selected},${labels[$i]}"
    fi
  done

  local chosen
  chosen=$(printf "%s\n" "$input" | gum choose \
    --no-limit \
    --header "Features (space to toggle, enter to save)" \
    --selected "$selected") || return 1

  # Reset state, then mark each chosen label as on.
  for i in "${!keys[@]}"; do state[$i]=0; done
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    for i in "${!keys[@]}"; do
      if [ "${labels[$i]}" = "$line" ]; then
        state[$i]=1
        break
      fi
    done
  done <<< "$chosen"
}

# --- numbered-loop fallback (no external deps) ---
configure_with_loop() {
  echo ""
  echo "claude-statusline — configure"
  echo ""
  echo "Icon mode:  1) emoji   2) nerd   3) unicode   4) ascii"
  printf "  choose [current: %s] > " "$icons"
  read -r pick
  case "$pick" in
    1) icons=emoji ;; 2) icons=nerd ;; 3) icons=unicode ;; 4) icons=ascii ;;
  esac

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
}

# --- dispatch ---
if offer_gum_install; then
  configure_with_gum || { echo "Cancelled. No changes saved."; exit 1; }
else
  configure_with_loop
fi

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
