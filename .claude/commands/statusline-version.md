Show the installed claude-statusline version and check GitHub for a newer one. Takes no arguments.

Prints the version stamped into your install (`~/.claude/statusline/VERSION`) and compares it against the latest on GitHub's main branch, telling you whether an update is available. This is **claude-statusline's own** version — for the Claude Code (host app) version badge, see `/statusline-claude-version`.

**How it works**
- Reads the local `VERSION` file and fetches `VERSION` from the repo (one curl). Nothing is sent anywhere.

Run this command via Bash:

~/.claude/statusline/version-check.sh

Report the output to the user.
