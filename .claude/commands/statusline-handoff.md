Toggle the handoff segment in the statusline. Pass "on"/"true" to enable or "off"/"false" to disable. Toggles if no argument given. On by default; it stays hidden until a session hands work off.

Shows work this session handed to another session, for example a helper running on a second account:
- `🔀 Enterprise: working 1m05s · <task>` while the helper runs (yellow)
- `🔀 Enterprise ×3 · 4m ago` afterwards: how many tasks it ran and when the last one finished (dim)
- `🔀 Enterprise: failed · <reason>` for 15 minutes after a failure (red)
- `🔀 Enterprise: no answer` when a task has said "working" for more than 30 minutes

**How it works**
- Reads `$CLAUDE_DIR/.statusline-state/handoff-<session_id>.json` (`$CLAUDE_DIR` is `CLAUDE_CONFIG_DIR`, or `~/.claude`). Whatever runs the handoff writes that file; the README documents the fields.
- No network calls.

**Disable anytime** with `/statusline-handoff off`.

Run this command via Bash:

~/.claude/statusline/switch-handoff.sh $ARGUMENTS

Report the output to the user.
