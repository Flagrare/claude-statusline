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

# Nerd Font detection
has_nerd_font=false
if fc-list 2>/dev/null | grep -qi "nerd"; then
  has_nerd_font=true
elif ls ~/Library/Fonts/*[Nn]erd* 2>/dev/null | grep -q .; then
  has_nerd_font=true
elif ls /usr/share/fonts/**/*[Nn]erd* 2>/dev/null | grep -q .; then
  has_nerd_font=true
fi

icon_mode="emoji"
if [ "$has_nerd_font" = true ]; then
  echo "  nerd font: detected"
  printf "  Use Nerd Font icons instead of emoji? [y/N] "
  read -r answer
  case "$answer" in
    [yY]*) icon_mode="nerd" ;;
  esac
else
  echo "  icons: emoji (install a Nerd Font and re-run for glyph mode)"
fi

# Cost display
show_cost="false"
printf "  Show session cost? (API plan users only, not for Pro/Max/Teams) [y/N] "
read -r answer
case "$answer" in
  [yY]*) show_cost="true" ;;
esac

# --- download files ---
echo "Downloading..."

mkdir -p "$INSTALL_DIR" "$COMMANDS_DIR" "$CLAUDE_DIR"

download "$BASE_URL/statusline.sh" "$INSTALL_DIR/statusline.sh"
download "$BASE_URL/usage-poller.sh" "$INSTALL_DIR/usage-poller.sh"
download "$BASE_URL/switch-icons.sh" "$INSTALL_DIR/switch-icons.sh"
download "$BASE_URL/switch-cost.sh" "$INSTALL_DIR/switch-cost.sh"
download "$BASE_URL/switch-sonnet.sh" "$INSTALL_DIR/switch-sonnet.sh"
download "$BASE_URL/switch-session-duration.sh" "$INSTALL_DIR/switch-session-duration.sh"
download "$BASE_URL/switch-token-speed.sh" "$INSTALL_DIR/switch-token-speed.sh"
download "$BASE_URL/switch-compaction.sh" "$INSTALL_DIR/switch-compaction.sh"
download "$BASE_URL/switch-git-diff-stats.sh" "$INSTALL_DIR/switch-git-diff-stats.sh"
download "$BASE_URL/switch-pr.sh" "$INSTALL_DIR/switch-pr.sh"
download "$BASE_URL/switch-worktree.sh" "$INSTALL_DIR/switch-worktree.sh"
download "$BASE_URL/switch-conflicts.sh" "$INSTALL_DIR/switch-conflicts.sh"
download "$BASE_URL/switch-output-style.sh" "$INSTALL_DIR/switch-output-style.sh"
download "$BASE_URL/switch-session-id.sh" "$INSTALL_DIR/switch-session-id.sh"
download "$BASE_URL/switch-version.sh" "$INSTALL_DIR/switch-version.sh"
download "$BASE_URL/switch-cwd.sh" "$INSTALL_DIR/switch-cwd.sh"
download "$BASE_URL/switch-extra-usage.sh" "$INSTALL_DIR/switch-extra-usage.sh"
download "$BASE_URL/switch-fast-mode.sh" "$INSTALL_DIR/switch-fast-mode.sh"
download "$BASE_URL/switch-context-warning.sh" "$INSTALL_DIR/switch-context-warning.sh"
download "$BASE_URL/.claude/commands/statusline-update.md" "$COMMANDS_DIR/statusline-update.md"
download "$BASE_URL/.claude/commands/statusline-icons.md" "$COMMANDS_DIR/statusline-icons.md"
download "$BASE_URL/.claude/commands/statusline-cost.md" "$COMMANDS_DIR/statusline-cost.md"
download "$BASE_URL/.claude/commands/statusline-sonnet.md" "$COMMANDS_DIR/statusline-sonnet.md"
download "$BASE_URL/.claude/commands/statusline-session-duration.md" "$COMMANDS_DIR/statusline-session-duration.md"
download "$BASE_URL/.claude/commands/statusline-token-speed.md" "$COMMANDS_DIR/statusline-token-speed.md"
download "$BASE_URL/.claude/commands/statusline-compaction.md" "$COMMANDS_DIR/statusline-compaction.md"
download "$BASE_URL/.claude/commands/statusline-git-diff-stats.md" "$COMMANDS_DIR/statusline-git-diff-stats.md"
download "$BASE_URL/.claude/commands/statusline-pr.md" "$COMMANDS_DIR/statusline-pr.md"
download "$BASE_URL/.claude/commands/statusline-worktree.md" "$COMMANDS_DIR/statusline-worktree.md"
download "$BASE_URL/.claude/commands/statusline-conflicts.md" "$COMMANDS_DIR/statusline-conflicts.md"
download "$BASE_URL/.claude/commands/statusline-output-style.md" "$COMMANDS_DIR/statusline-output-style.md"
download "$BASE_URL/.claude/commands/statusline-session-id.md" "$COMMANDS_DIR/statusline-session-id.md"
download "$BASE_URL/.claude/commands/statusline-version.md" "$COMMANDS_DIR/statusline-version.md"
download "$BASE_URL/.claude/commands/statusline-cwd.md" "$COMMANDS_DIR/statusline-cwd.md"
download "$BASE_URL/.claude/commands/statusline-extra-usage.md" "$COMMANDS_DIR/statusline-extra-usage.md"
download "$BASE_URL/.claude/commands/statusline-fast-mode.md" "$COMMANDS_DIR/statusline-fast-mode.md"
download "$BASE_URL/.claude/commands/statusline-context-warning.md" "$COMMANDS_DIR/statusline-context-warning.md"

chmod +x "$INSTALL_DIR/statusline.sh" "$INSTALL_DIR/usage-poller.sh" \
         "$INSTALL_DIR/switch-icons.sh" "$INSTALL_DIR/switch-cost.sh" \
         "$INSTALL_DIR/switch-sonnet.sh" \
         "$INSTALL_DIR/switch-session-duration.sh" \
         "$INSTALL_DIR/switch-token-speed.sh" \
         "$INSTALL_DIR/switch-compaction.sh" \
         "$INSTALL_DIR/switch-git-diff-stats.sh" \
         "$INSTALL_DIR/switch-pr.sh" \
         "$INSTALL_DIR/switch-worktree.sh" \
         "$INSTALL_DIR/switch-conflicts.sh" \
         "$INSTALL_DIR/switch-output-style.sh" \
         "$INSTALL_DIR/switch-session-id.sh" \
         "$INSTALL_DIR/switch-version.sh" \
         "$INSTALL_DIR/switch-cwd.sh" \
         "$INSTALL_DIR/switch-extra-usage.sh" \
         "$INSTALL_DIR/switch-fast-mode.sh" \
         "$INSTALL_DIR/switch-context-warning.sh"

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

echo ""
echo "Installed claude-statusline."
echo "  Location: $INSTALL_DIR"
echo "  Icons:    $icon_mode"
echo "  Cost:     $show_cost"
echo "  Sonnet:   disabled (enable with /statusline-sonnet — Pro/Max only)"
echo ""
echo "Restart Claude Code to see the status bar."
echo "Use /statusline-update to get future updates."
