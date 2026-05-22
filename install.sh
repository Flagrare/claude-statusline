#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATUSLINE_SCRIPT="$SCRIPT_DIR/statusline.sh"
CLAUDE_DIR="$HOME/.claude"
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

# --- check dependencies ---
echo "Checking dependencies..."

# jq (required at runtime)
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

# python3 or jq for install-time JSON editing (python3 preferred)
has_json_editor=false
if command -v python3 &>/dev/null; then
  has_json_editor=true
  echo "  python3: ok (used for settings.json editing)"
elif command -v jq &>/dev/null; then
  has_json_editor=true
  echo "  jq: ok (used for settings.json editing)"
fi

if [ "$has_json_editor" = false ]; then
  echo "Error: python3 or jq is required to update settings.json."
  exit 1
fi

# Nerd Font detection
has_nerd_font=false
if fc-list 2>/dev/null | grep -qi "nerd"; then
  has_nerd_font=true
elif ls ~/Library/Fonts/*[Nn]erd* 2>/dev/null | grep -q .; then
  has_nerd_font=true
elif ls /usr/share/fonts/**/*[Nn]erd* 2>/dev/null | grep -q .; then
  has_nerd_font=true
fi

# Icon mode selection
icon_mode="emoji"
if [ "$has_nerd_font" = true ]; then
  echo "  nerd font: detected"
  printf "  Use Nerd Font icons instead of emoji? (requires terminal font set to a Nerd Font) [y/N] "
  read -r answer
  case "$answer" in
    [yY]*) icon_mode="nerd" ;;
  esac
else
  printf "\n"
  printf "  Icons will use emoji (🧠🔥🍃⚡) which work in all terminals.\n"
  printf "  For Nerd Font icons instead, install one and re-run this installer.\n"
  pm=$(detect_pkg_manager)
  nf_install_cmd=""
  case "$pm" in
    brew) nf_install_cmd="brew install --cask font-jetbrains-mono-nerd-font" ;;
    pacman) nf_install_cmd="sudo pacman -S --noconfirm ttf-jetbrains-mono-nerd" ;;
  esac

  if [ -n "$nf_install_cmd" ]; then
    printf "  Install JetBrainsMono Nerd Font now? [y/N] "
    read -r answer
    case "$answer" in
      [yY]*)
        eval "$nf_install_cmd"
        has_nerd_font=true
        printf "  Installed! To use Nerd Font icons, set your terminal font to\n"
        printf "  'JetBrainsMono Nerd Font' and re-run: bash install.sh\n"
        ;;
    esac
  fi
  printf "\n"
fi

# --- install ---
chmod +x "$STATUSLINE_SCRIPT"

mkdir -p "$CLAUDE_DIR"
if [ ! -f "$SETTINGS" ]; then
  echo '{}' > "$SETTINGS"
fi

# Patch settings.json
if command -v python3 &>/dev/null; then
  python3 - "$SETTINGS" "$STATUSLINE_SCRIPT" <<'PYEOF'
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
  jq --arg cmd "$STATUSLINE_SCRIPT" '. + {statusLine: {type: "command", "command": $cmd}}' "$SETTINGS" > "$tmp"
  mv "$tmp" "$SETTINGS"
fi

# Write config for the statusline script
CONFIG_FILE="$SCRIPT_DIR/.statusline.conf"
echo "ICONS=$icon_mode" > "$CONFIG_FILE"

echo "Installed claude-statusline."
echo "  Script: $STATUSLINE_SCRIPT"
echo "  Config: $SETTINGS"
echo "  Icons:  $icon_mode"
echo ""
echo "Restart Claude Code to see the status bar."
