#!/usr/bin/env bash
# Fetches per-model usage from Anthropic's OAuth endpoint and caches it for
# statusline.sh. Silent on every error path — a stale cache continues to serve
# until the next successful fetch.
#
# Triggered in the background by statusline.sh when SHOW_MODEL_USAGE=true and
# the cache is missing or older than the TTL (~5 min). Reads the OAuth access
# token Claude Code itself stores: macOS keychain ("Claude Code-credentials")
# or ~/.claude/.credentials.json on Linux.
#
# With CLAUDE_CONFIG_DIR set, Claude Code keeps that profile's login apart: the
# keychain entry gets a suffix (first 8 hex chars of the SHA-256 of the
# directory path) and the credentials file lives inside the directory. The
# cache lives there too, so each profile shows its own account's usage. If the
# profile's token can't be found, nothing is fetched: falling back to the
# default login would show another account's numbers.
#
# This is the same endpoint Claude Code's /usage command uses internally.

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
CLAUDE_DIR="${CLAUDE_DIR%/}"
CACHE_FILE="$CLAUDE_DIR/.statusline-usage-cache.json"
ENDPOINT="https://api.anthropic.com/api/oauth/usage"

command -v jq &>/dev/null || exit 0
command -v curl &>/dev/null || exit 0

sha8() {
  if command -v shasum &>/dev/null; then printf "%s" "$1" | shasum -a 256 | cut -c1-8
  else printf "%s" "$1" | sha256sum | cut -c1-8; fi
}

# Keychain service names to try for this profile, most likely first.
keychain_services() {
  if [ -z "${CLAUDE_CONFIG_DIR:-}" ]; then
    echo "Claude Code-credentials"
    return
  fi
  local raw="$CLAUDE_CONFIG_DIR" resolved
  echo "Claude Code-credentials-$(sha8 "$raw")"
  resolved=$(cd "$raw" 2>/dev/null && pwd -P)
  [ -n "$resolved" ] && [ "$resolved" != "$raw" ] && echo "Claude Code-credentials-$(sha8 "$resolved")"
  [ "${raw%/}" != "$raw" ] && echo "Claude Code-credentials-$(sha8 "${raw%/}")"
}

get_token() {
  local svc tok
  if [[ "$(uname -s)" == "Darwin" ]]; then
    while IFS= read -r svc; do
      tok=$(security find-generic-password -s "$svc" -a "$USER" -w 2>/dev/null \
        | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
      [ -n "$tok" ] && { printf "%s" "$tok"; return; }
    done < <(keychain_services)
  fi
  # Linux, and macOS when the keychain write failed (Claude Code falls back to
  # the file then).
  jq -r '.claudeAiOauth.accessToken // empty' "$CLAUDE_DIR/.credentials.json" 2>/dev/null
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
