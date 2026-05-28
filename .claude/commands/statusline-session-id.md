Toggle the session ID display in the statusline. Pass "on"/"true" to enable or "off"/"false" to disable. Toggles if no argument given.

Adds a dim 6-character prefix of the current session UUID to the end of the statusline. Useful when juggling multiple sessions in tmux/iTerm splits.

**How it works**
- Reads `.session_id` (or `.sessionId`) from Claude Code's stdin JSON and renders the first 6 characters.

**Disable anytime** with `/statusline-session-id off`.

Run this command via Bash:

~/.claude/statusline/switch-session-id.sh $ARGUMENTS

Report the output to the user.
