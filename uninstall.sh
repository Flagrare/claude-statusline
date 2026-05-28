#!/usr/bin/env bash
set -e

CLAUDE_DIR="$HOME/.claude"
INSTALL_DIR="$CLAUDE_DIR/statusline"
COMMANDS_DIR="$CLAUDE_DIR/commands"
SETTINGS="$CLAUDE_DIR/settings.json"

if [ -f "$SETTINGS" ]; then
  if command -v python3 &>/dev/null; then
    python3 - "$SETTINGS" <<'PYEOF'
import json, sys
settings_path = sys.argv[1]
with open(settings_path) as f:
    data = json.load(f)
data.pop("statusLine", None)
with open(settings_path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PYEOF
  elif command -v jq &>/dev/null; then
    tmp=$(mktemp)
    jq 'del(.statusLine)' "$SETTINGS" > "$tmp"
    mv "$tmp" "$SETTINGS"
  else
    echo "Error: python3 or jq is required."
    echo "Manually remove the \"statusLine\" key from $SETTINGS"
    exit 1
  fi
  echo "Removed statusLine config from $SETTINGS"
fi

rm -f "$COMMANDS_DIR/statusline-update.md"
rm -f "$COMMANDS_DIR/statusline-icons.md"
rm -f "$COMMANDS_DIR/statusline-cost.md"
rm -f "$COMMANDS_DIR/statusline-sonnet.md"
echo "Removed slash commands."

rm -rf "$INSTALL_DIR"
echo "Removed $INSTALL_DIR"

rm -f "$CLAUDE_DIR/.statusline-usage-cache.json"

echo ""
echo "claude-statusline uninstalled. Restart Claude Code to apply."
