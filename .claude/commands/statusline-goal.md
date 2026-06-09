Toggle the `/goal` indicator in the statusline. Pass "on"/"true" to enable or "off"/"false" to disable. Toggles if no argument given.

Renders the active goal condition on row 1 (e.g. `🎯 all tests in test/auth pass`) while a `/goal` is running. The segment suppresses entirely when no goal is active or the evaluator has just confirmed it met. **On by default** — the segment is silent until you actually set a goal, so leaving it on costs nothing.

**How it works**
- Reads `attachment.type:"goal_status"` records from the active session JSONL. Renders the most recent one when `met:false`; suppresses when `met:true` (the goal cleared) or no record exists.

**Disable anytime** with `/statusline-goal off`.

Run this command via Bash:

~/.claude/statusline/switch-goal.sh $ARGUMENTS

Report the output to the user.
