#!/usr/bin/env bash
set -e

REPO="Flagrare/claude-statusline"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/$REPO/$BRANCH"

CLAUDE_DIR="$HOME/.claude"
INSTALL_DIR="$CLAUDE_DIR/statusline"
COMMANDS_DIR="$CLAUDE_DIR/commands"

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

SETTINGS="$CLAUDE_DIR/settings.json"

# --- migrate from old clone-based install ---
migrate_old_install() {
  local old_script old_dir old_conf
  old_script=$(jq -r '.statusLine.command // empty' "$SETTINGS" 2>/dev/null)
  [ -z "$old_script" ] && return 1
  old_dir=$(dirname "$old_script")

  [ "$old_dir" = "$INSTALL_DIR" ] && return 1

  if [ ! -f "$old_dir/.statusline.conf" ]; then
    return 1
  fi

  echo "Detected old install at $old_dir"
  echo "Migrating to $INSTALL_DIR..."

  mkdir -p "$INSTALL_DIR"
  cp "$old_dir/.statusline.conf" "$INSTALL_DIR/.statusline.conf"

  return 0
}

if [ ! -d "$INSTALL_DIR" ]; then
  if [ -f "$SETTINGS" ] && migrate_old_install; then
    echo "Config migrated."
  else
    echo "claude-statusline is not installed. Run the installer instead:"
    echo "  bash <(curl -fsSL $BASE_URL/install.sh)"
    exit 1
  fi
fi

echo "Updating claude-statusline..."

mkdir -p "$INSTALL_DIR" "$COMMANDS_DIR"

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

chmod +x "$INSTALL_DIR/statusline.sh" "$INSTALL_DIR/usage-poller.sh" \
         "$INSTALL_DIR/switch-icons.sh" "$INSTALL_DIR/switch-cost.sh" \
         "$INSTALL_DIR/switch-sonnet.sh" \
         "$INSTALL_DIR/switch-session-duration.sh" \
         "$INSTALL_DIR/switch-token-speed.sh" \
         "$INSTALL_DIR/switch-compaction.sh" \
         "$INSTALL_DIR/switch-git-diff-stats.sh" \
         "$INSTALL_DIR/switch-pr.sh" \
         "$INSTALL_DIR/switch-worktree.sh" \
         "$INSTALL_DIR/switch-conflicts.sh"

# --- update settings.json to point to new location ---
if [ -f "$SETTINGS" ]; then
  current_cmd=$(jq -r '.statusLine.command // empty' "$SETTINGS" 2>/dev/null)
  if [ -n "$current_cmd" ] && [ "$current_cmd" != "$INSTALL_DIR/statusline.sh" ]; then
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
    echo "Updated settings.json to point to new location."
  fi
fi

echo "Done. Your config (.statusline.conf) was preserved."
