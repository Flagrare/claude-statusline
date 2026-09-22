#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="$SCRIPT_DIR/.statusline.conf"

# Read current value (default false; falls back to the pre-v2.13.0 key)
current=$(grep '^SHOW_MODEL_USAGE=' "$CONF" 2>/dev/null | cut -d= -f2)
[ -z "$current" ] && current=$(grep '^SHOW_SONNET_LIMIT=' "$CONF" 2>/dev/null | cut -d= -f2)
[ -z "$current" ] && current="false"

# Determine target
arg="${1:-}"
case "$arg" in
  true|on)   target="true"  ;;
  false|off) target="false" ;;
  "")
    if [ "$current" = "true" ]; then target="false"; else target="true"; fi
    ;;
  *)
    echo "Usage: switch-model-usage.sh [true|on|false|off]"
    exit 1
    ;;
esac

# Write back
sed -i '' '/^SHOW_SONNET_LIMIT=/d' "$CONF" 2>/dev/null
if grep -q '^SHOW_MODEL_USAGE=' "$CONF" 2>/dev/null; then
  sed -i '' "s/^SHOW_MODEL_USAGE=.*/SHOW_MODEL_USAGE=${target}/" "$CONF"
else
  echo "SHOW_MODEL_USAGE=${target}" >> "$CONF"
fi

if [ "$target" = "true" ]; then
  cat <<'MSG'
Per-model usage tracking: on

  What it does
    Adds a segment per model with its own weekly cap (e.g. "fable:N% [resets]"),
    alongside the combined 7-day limit. The model names come from the
    usage endpoint, so the segment follows whichever model your plan scopes.

  Requirements
    Claude Pro or Max plan. API plan users will see no change — the endpoint
    reports no per-model caps for them.

  How it gets the data
    Every ~5 minutes a background poller calls
      https://api.anthropic.com/api/oauth/usage
    using the OAuth token Claude Code itself stores for /usage. This is the
    same endpoint /usage uses internally — no third parties involved. The
    response is cached at ~/.claude/.statusline-usage-cache.json.

  macOS: keychain prompt
    The first time the poller runs, macOS shows
      "claude-statusline wants to use your confidential information
       stored in 'Claude Code-credentials'."
    Click "Always Allow" so you don't see it again.

  Disable anytime
    /statusline-model-usage off

  Restart Claude Code (or trigger any prompt) to see the new segment.
MSG
else
  echo "Per-model usage tracking: off"
fi
