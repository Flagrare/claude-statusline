Toggle the Claude Code version badge in the statusline. Pass "on"/"true" to enable or "off"/"false" to disable. Toggles if no argument given.

Adds a trailing dim `vX.Y.Z` showing the version of **Claude Code** (the host app) you're running — handy for spotting when Claude Code updates under you. This is the host app's version, not claude-statusline's own; for that, use `/statusline-version`.

**How it works**
- Reads `.version` from Claude Code's stdin JSON.

**Disable anytime** with `/statusline-claude-version off`.

Run this command via Bash:

~/.claude/statusline/switch-claude-version.sh $ARGUMENTS

Report the output to the user.
