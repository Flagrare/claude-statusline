#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="$SCRIPT_DIR/.statusline.conf"

# Read current value (default false)
current=$(grep '^SHOW_SONNET_LIMIT=' "$CONF" 2>/dev/null | cut -d= -f2)
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
    echo "Usage: switch-sonnet.sh [true|on|false|off]"
    exit 1
    ;;
esac

# Write back
if grep -q '^SHOW_SONNET_LIMIT=' "$CONF" 2>/dev/null; then
  sed -i '' "s/^SHOW_SONNET_LIMIT=.*/SHOW_SONNET_LIMIT=${target}/" "$CONF"
else
  echo "SHOW_SONNET_LIMIT=${target}" >> "$CONF"
fi

if [ "$target" = "true" ]; then
  cat <<'MSG'
Sonnet usage tracking: on

  What it does
    Adds a "sonnet:N% [resets]" segment (and "opus:N%" when applicable)
    showing the per-model weekly cap Anthropic enforces in addition to the
    combined 7-day limit.

  Requirements
    Claude Pro or Max plan. API plan users will see no change — the endpoint
    returns null for these fields.

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
    /statusline-sonnet off

  Restart Claude Code (or trigger any prompt) to see the new segment.
MSG
else
  echo "Sonnet usage tracking: off"
fi
