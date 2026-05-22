#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"
TARGET="$CLAUDE_DIR/statusline.sh"

# --- checks ---
if ! command -v jq &>/dev/null; then
  echo "Error: jq is required. Install it with your package manager (e.g. apt install jq / brew install jq)."
  exit 1
fi

# --- install script ---
mkdir -p "$CLAUDE_DIR"
cp "$SCRIPT_DIR/statusline.sh" "$TARGET"
chmod +x "$TARGET"

# --- wire up settings.json ---
if [ ! -f "$SETTINGS" ]; then
  echo '{}' > "$SETTINGS"
fi

updated=$(jq --arg cmd "$TARGET" '. + {statusLine: {type: "command", command: $cmd}}' "$SETTINGS")
echo "$updated" > "$SETTINGS"

echo "✓ Installed to $TARGET"
echo "✓ settings.json updated"
echo ""
echo "Restart Claude Code to see the status bar."
