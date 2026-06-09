Toggle the `/loop` indicator in the statusline. Pass "on"/"true" to enable or "off"/"false" to disable. Toggles if no argument given.

Renders an active `/loop` schedule on row 1 (e.g. `🔁 Every 10 minutes`). When multiple loops are running, shows a count instead (`🔁 3 loops`). The segment suppresses entirely when no loop is active. **On by default** — the segment is silent unless you've actually scheduled something.

**How it works**
- Scans `CronCreate` tool_use records tagged `attributionSkill:"loop"` in the active session JSONL, pairs each with its `toolUseResult.id` from the next event, then subtracts any `CronDelete` referencing the same id. Whatever remains is currently active.

**Disable anytime** with `/statusline-loop off`.

Run this command via Bash:

~/.claude/statusline/switch-loop.sh $ARGUMENTS

Report the output to the user.
