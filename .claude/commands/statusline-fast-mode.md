Toggle the fast-mode badge in the statusline. Pass "on"/"true" to enable or "off"/"false" to disable. Toggles if no argument given. Default is on.

When Claude Code's Fast mode is active, a yellow `⚡ fast` badge appears on the top row next to the thinking effort. Hidden whenever Fast mode is off, so it never adds clutter during normal sessions.

**How it works**
- Reads the `fast_mode` boolean from the status JSON Claude Code sends on stdin. No extra process, no network.

**Disable anytime** with `/statusline-fast-mode off`.

Run this command via Bash:

~/.claude/statusline/switch-fast-mode.sh $ARGUMENTS

Report the output to the user.
