Toggle the token speed display in the statusline. Pass "on"/"true" to enable or "off"/"false" to disable. Toggles if no argument given.

Adds a `💨 N↓ N↑/s` segment showing the last assistant turn's input/output tokens per second. Input rate includes cached tokens (since they're billed at lower rates but still flow through the model); output rate is generated tokens only.

**How it works**
- Reads the most recent user→assistant timestamp pair and token counts from the active session's JSONL.
- Useful for spotting when a turn is dragging on tool-call latency vs. generation.
- Skipped on the first turn (no prior assistant entry to compare against).

**Disable anytime** with `/statusline-token-speed off`.

Run this command via Bash:

~/.claude/statusline/switch-token-speed.sh $ARGUMENTS

Report the output to the user.
