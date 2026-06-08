Toggle the over-200k context warning in the statusline. Pass "on"/"true" to enable or "off"/"false" to disable. Toggles if no argument given. Default is on.

Once the session crosses the 200k-token threshold — the point where long-context pricing applies on the 1M-context models — a red `⚠ >200k` badge appears on the top row, just after the context bar. Hidden below the threshold, so it only speaks up when it matters.

**How it works**
- Reads the `exceeds_200k_tokens` boolean from the status JSON Claude Code sends on stdin. No extra process, no network.

**Disable anytime** with `/statusline-context-warning off`.

Run this command via Bash:

~/.claude/statusline/switch-context-warning.sh $ARGUMENTS

Report the output to the user.
