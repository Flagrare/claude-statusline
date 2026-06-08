#!/usr/bin/env bash
set -e

REPO="Flagrare/claude-statusline"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/$REPO/$BRANCH"

CLAUDE_DIR="$HOME/.claude"
INSTALL_DIR="$CLAUDE_DIR/statusline"
COMMANDS_DIR="$CLAUDE_DIR/commands"
SETTINGS="$CLAUDE_DIR/settings.json"

# --- helpers ---
ask_install() {
  local tool=$1
  local install_cmd=$2
  printf "\n⚠  '%s' is not installed but is required.\n" "$tool"
  printf "   Install command: %s\n" "$install_cmd"
  printf "   Install now? [Y/n] "
  read -r answer
  case "$answer" in
    [nN]*) return 1 ;;
    *)     eval "$install_cmd" ;;
  esac
}

detect_pkg_manager() {
  if command -v brew &>/dev/null; then
    echo "brew"
  elif command -v apt-get &>/dev/null; then
    echo "apt"
  elif command -v dnf &>/dev/null; then
    echo "dnf"
  elif command -v pacman &>/dev/null; then
    echo "pacman"
  else
    echo ""
  fi
}

install_cmd_for() {
  local tool=$1
  local pm
  pm=$(detect_pkg_manager)
  case "$pm" in
    brew)   echo "brew install $tool" ;;
    apt)    echo "sudo apt-get install -y $tool" ;;
    dnf)    echo "sudo dnf install -y $tool" ;;
    pacman) echo "sudo pacman -S --noconfirm $tool" ;;
    *)      echo "" ;;
  esac
}

download() {
  local url=$1
  local dest=$2
  if command -v curl &>/dev/null; then
    curl -fsSL "$url" -o "$dest"
  elif command -v wget &>/dev/null; then
    wget -qO "$dest" "$url"
  else
    echo "Error: curl or wget is required."
    exit 1
  fi
}

# Download every file listed in files.manifest to its destination. The manifest
# is the single source of truth for the distributable file set, shared with
# update.sh — adding a segment is a one-line manifest edit, not a two-script one.
fetch_from_manifest() {
  local manifest kind path dest
  manifest=$(mktemp)
  download "$BASE_URL/files.manifest" "$manifest"
  while read -r kind path; do
    case "$kind" in
      ''|\#*) continue ;;
      bin) dest="$INSTALL_DIR/$(basename "$path")"; download "$BASE_URL/$path" "$dest"; chmod +x "$dest" ;;
      dat) dest="$INSTALL_DIR/$(basename "$path")"; download "$BASE_URL/$path" "$dest" ;;
      cmd) dest="$COMMANDS_DIR/$(basename "$path")"; download "$BASE_URL/$path" "$dest" ;;
    esac
  done < "$manifest"
  rm -f "$manifest"
}

# --- check dependencies ---
echo "Checking dependencies..."

if ! command -v jq &>/dev/null; then
  cmd=$(install_cmd_for jq)
  if [ -n "$cmd" ]; then
    if ! ask_install "jq" "$cmd"; then
      echo "Error: jq is required for the statusline to parse JSON input."
      echo "Install it manually: https://jqlang.github.io/jq/download/"
      exit 1
    fi
  else
    echo "Error: jq is required but no supported package manager was found."
    echo "Install it manually: https://jqlang.github.io/jq/download/"
    exit 1
  fi
fi
echo "  jq: ok"

# --- setup mode ---
printf "\nSetup mode:\n"
printf "  1) Quick    — recommended defaults (icons + cost)\n"
printf "  2) Advanced — choose every feature\n"
printf "> [1] "
read -r mode_answer
setup_mode="quick"
case "$mode_answer" in 2|advanced|Advanced) setup_mode="advanced" ;; esac

# Nerd Font detection (sets the default icon mode for both paths)
has_nerd_font=false
if fc-list 2>/dev/null | grep -qi "nerd"; then
  has_nerd_font=true
elif ls ~/Library/Fonts/*[Nn]erd* 2>/dev/null | grep -q .; then
  has_nerd_font=true
elif ls /usr/share/fonts/**/*[Nn]erd* 2>/dev/null | grep -q .; then
  has_nerd_font=true
fi
icon_mode="emoji"; [ "$has_nerd_font" = true ] && icon_mode="nerd"
show_cost="false"

# Quick asks the two classic questions; Advanced defers every choice to the
# interactive configurator (run after download), so it skips them here.
if [ "$setup_mode" = "quick" ]; then
  icon_mode="emoji"
  if [ "$has_nerd_font" = true ]; then
    echo "  nerd font: detected"
    printf "  Use Nerd Font icons instead of emoji? [y/N] "
    read -r answer
    case "$answer" in [yY]*) icon_mode="nerd" ;; esac
  else
    echo "  icons: emoji (install a Nerd Font and re-run for glyph mode)"
  fi
  printf "  Show session cost? (API plan users only, not for Pro/Max/Teams) [y/N] "
  read -r answer
  case "$answer" in [yY]*) show_cost="true" ;; esac
fi

# --- download files ---
echo "Downloading..."

mkdir -p "$INSTALL_DIR" "$COMMANDS_DIR" "$CLAUDE_DIR"

fetch_from_manifest

# --- write config ---
# SHOW_SONNET_LIMIT defaults to false — feature is opt-in via /statusline-sonnet
# because it reads the OAuth token from the macOS keychain (triggers a one-time
# permission dialog) and makes outbound calls to api.anthropic.com.
# JSONL signals (session duration, token speed, compaction) default to false —
# enable per feature via /statusline-session-duration, /statusline-token-speed,
# /statusline-compaction.
cat > "$INSTALL_DIR/.statusline.conf" <<CONF
ICONS=$icon_mode
SHOW_COST=$show_cost
SHOW_SONNET_LIMIT=false
SHOW_SESSION_DURATION=false
SHOW_TOKEN_SPEED=false
SHOW_COMPACTION=false
SHOW_GIT_DIFF_STATS=false
SHOW_PR=false
SHOW_WORKTREE=true
SHOW_CONFLICTS=true
SHOW_OUTPUT_STYLE=false
SHOW_SESSION_ID=false
SHOW_VERSION=false
SHOW_CWD=false
SHOW_EXTRA_USAGE=false
SHOW_FAST_MODE=true
SHOW_CONTEXT_WARNING=true
CONTEXT_WARNING_TOKENS=200000
CONF

# --- patch settings.json ---
if [ ! -f "$SETTINGS" ]; then
  echo '{}' > "$SETTINGS"
fi

if command -v python3 &>/dev/null; then
  python3 - "$SETTINGS" "$INSTALL_DIR/statusline.sh" <<'PYEOF'
import json, sys
settings_path, script_path = sys.argv[1], sys.argv[2]
with open(settings_path) as f:
    data = json.load(f)
data["statusLine"] = {"type": "command", "command": script_path}
with open(settings_path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PYEOF
elif command -v jq &>/dev/null; then
  tmp=$(mktemp)
  jq --arg cmd "$INSTALL_DIR/statusline.sh" '. + {statusLine: {type: "command", command: $cmd}}' "$SETTINGS" > "$tmp"
  mv "$tmp" "$SETTINGS"
fi

# Advanced: hand off to the interactive configurator to pick icon mode + features.
if [ "$setup_mode" = "advanced" ] && [ -x "$INSTALL_DIR/configure.sh" ]; then
  bash "$INSTALL_DIR/configure.sh"
fi

echo ""
echo "Installed claude-statusline."
echo "  Location: $INSTALL_DIR"
if [ "$setup_mode" != "advanced" ]; then
  echo "  Icons:    $icon_mode"
  echo "  Cost:     $show_cost"
fi
echo ""
echo "Restart Claude Code to see the status bar."
echo "Reconfigure anytime with /statusline-config; update with /statusline-update."
