Toggle the session duration display in the statusline. Pass "on"/"true" to enable or "off"/"false" to disable. Toggles if no argument given.

Adds a `⏱ Nh Nm` segment showing how long the current Claude Code session has been running, computed from the first message timestamp in the session transcript.

**How it works**
- Reads the first entry's timestamp from the active session's JSONL under `~/.claude/projects/<encoded-cwd>/`.
- No network calls, no external state — pure local read on every render.

**Disable anytime** with `/statusline-session-duration off`.

Run this command via Bash:

~/.claude/statusline/switch-session-duration.sh $ARGUMENTS

Report the output to the user.
