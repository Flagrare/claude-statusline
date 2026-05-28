#!/usr/bin/env bash
# Fetches per-model usage from Anthropic's OAuth endpoint and caches it for
# statusline.sh. Silent on every error path — a stale cache continues to serve
# until the next successful fetch.
#
# Triggered in the background by statusline.sh when SHOW_SONNET_LIMIT=true and
# the cache is missing or older than the TTL (~5 min). Reads the OAuth access
# token Claude Code itself stores: macOS keychain ("Claude Code-credentials")
# or ~/.claude/.credentials.json on Linux.
#
# This is the same endpoint Claude Code's /usage command uses internally.

CACHE_FILE="$HOME/.claude/.statusline-usage-cache.json"
ENDPOINT="https://api.anthropic.com/api/oauth/usage"

command -v jq &>/dev/null || exit 0
command -v curl &>/dev/null || exit 0

get_token() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    security find-generic-password -s "Claude Code-credentials" -a "$USER" -w 2>/dev/null \
      | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null
  else
    jq -r '.claudeAiOauth.accessToken // empty' "$HOME/.claude/.credentials.json" 2>/dev/null
  fi
}

token=$(get_token)
[ -z "$token" ] && exit 0

tmp=$(mktemp) || exit 0
trap 'rm -f "$tmp"' EXIT

http_code=$(curl -sS --max-time 5 \
  -H "Authorization: Bearer $token" \
  -H "User-Agent: claude-cli/2.1" \
  -o "$tmp" -w "%{http_code}" \
  "$ENDPOINT" 2>/dev/null) || exit 0

# Only commit the cache on a clean 200 + parseable JSON. On 401 the access
# token has expired; Claude Code itself refreshes the keychain entry on its
# next API call, so the next poll picks up the new token automatically.
if [ "$http_code" = "200" ] && jq -e . "$tmp" >/dev/null 2>&1; then
  mkdir -p "$(dirname "$CACHE_FILE")"
  mv "$tmp" "$CACHE_FILE"
fi
