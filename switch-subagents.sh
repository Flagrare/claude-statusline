#!/usr/bin/env bash
# Turn the custom subagent rows on or off by setting or removing
# subagentStatusLine in Claude Code's settings.json.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SETTINGS="${CLAUDE_DIR%/}/settings.json"
SCRIPT="$SCRIPT_DIR/subagent-statusline.sh"
command -v jq &>/dev/null || { echo "jq is required"; exit 1; }
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"

current=$(jq -r 'if .subagentStatusLine then "true" else "false" end' "$SETTINGS" 2>/dev/null)
case "${1:-}" in
  true|on)   target="true" ;;
  false|off) target="false" ;;
  "") if [ "$current" = "true" ]; then target="false"; else target="true"; fi ;;
  *) echo "Usage: switch-subagents.sh [true|on|false|off]"; exit 1 ;;
esac

tmp=$(mktemp) || exit 1
if [ "$target" = "true" ]; then
  jq --arg cmd "$SCRIPT" '.subagentStatusLine = {type: "command", command: $cmd}' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
  echo "Subagent rows: on (status, task, model + effort, elapsed, tokens and a token-rate sparkline per subagent)"
else
  jq 'del(.subagentStatusLine)' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
  echo "Subagent rows: off (Claude Code's default rows)"
fi
