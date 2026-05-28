Toggle the compaction counter in the statusline. Pass "on"/"true" to enable or "off"/"false" to disable. Toggles if no argument given.

Adds a `🔄N` marker next to the context % bar when one or more auto-compaction events have been detected in the current session.

**How it works**
- On every render, compares the current context percentage to the last-seen value (persisted at `~/.claude/.statusline-state/compaction-<session-id>.json`).
- A drop greater than 2 percentage points from a non-trivial baseline (>5%) is treated as a compaction event and increments the counter.
- The marker is hidden when the count is zero, so it only appears once a compaction has happened.

**Disable anytime** with `/statusline-compaction off`.

Run this command via Bash:

~/.claude/statusline/switch-compaction.sh $ARGUMENTS

Report the output to the user.
