Toggle custom subagent rows in the agent panel below the prompt. Pass "on"/"true" to enable or "off"/"false" to disable. Toggles if no argument given.

Replaces Claude Code's default `name · description · tokens` row with:

`● Explore · Reading the PR template… · sonnet high · 1m12s · 48k (24%) ▂▃▆█▇▅`

- Status mark: `●` running (yellow), `✓` done (green), `✗` failed (red), `■` stopped.
- What it's doing, trimmed to fit the row.
- Model and effort, elapsed time, tokens (and share of its context window), and a sparkline of how fast it has been using tokens over the last few refreshes.

**How it works**
- Sets `subagentStatusLine` in your Claude Code `settings.json` to `~/.claude/statusline/subagent-statusline.sh`; turning it off removes the key. No network calls.

Run this command via Bash:

~/.claude/statusline/switch-subagents.sh $ARGUMENTS

Report the output to the user.
