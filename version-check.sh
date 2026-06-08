#!/usr/bin/env bash
# Reports the installed claude-statusline version and checks GitHub for a newer
# one. The version is stamped into the VERSION file shipped alongside this
# script (see files.manifest); the latest is read from the repo's main branch.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_URL="https://raw.githubusercontent.com/Flagrare/claude-statusline/main"

installed="unknown"
[ -f "$SCRIPT_DIR/VERSION" ] && installed=$(tr -d '[:space:]' < "$SCRIPT_DIR/VERSION")
echo "claude-statusline v${installed}"

latest=""
if command -v curl >/dev/null 2>&1; then
  latest=$(curl -fsSL "$BASE_URL/VERSION" 2>/dev/null | tr -d '[:space:]')
elif command -v wget >/dev/null 2>&1; then
  latest=$(wget -qO- "$BASE_URL/VERSION" 2>/dev/null | tr -d '[:space:]')
fi

if [ -z "$latest" ]; then
  echo "Latest on GitHub: (couldn't check — no network, or curl/wget missing)"
elif [ "$installed" = "$latest" ]; then
  echo "Latest on GitHub: v${latest}  ✓ up to date"
else
  echo "Latest on GitHub: v${latest}  ⚠ update available — run /statusline-update"
fi
