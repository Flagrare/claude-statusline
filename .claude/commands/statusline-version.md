Toggle the Claude Code version badge in the statusline. Pass "on"/"true" to enable or "off"/"false" to disable. Toggles if no argument given.

Adds a trailing dim `vX.Y.Z` so you can see at a glance when Claude Code has been updated under you.

**How it works**
- Reads `.version` from Claude Code's stdin JSON.

**Disable anytime** with `/statusline-version off`.

Run this command via Bash:

~/.claude/statusline/switch-version.sh $ARGUMENTS

Report the output to the user.
