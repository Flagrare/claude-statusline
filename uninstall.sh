#!/usr/bin/env bash
set -e

SETTINGS="$HOME/.claude/settings.json"

if [ ! -f "$SETTINGS" ]; then
  echo "No settings.json found. Nothing to do."
  exit 0
fi

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
echo "You can delete this directory if you no longer need it."
