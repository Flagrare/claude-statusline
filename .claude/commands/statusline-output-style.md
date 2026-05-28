Toggle the output-style badge in the statusline. Pass "on"/"true" to enable or "off"/"false" to disable. Toggles if no argument given.

Adds a dim `[explanatory]` / `[learning]` / etc. badge next to the model name, so you can see at a glance which output style Claude is using.

**How it works**
- Reads `.output_style.name` from the JSON Claude Code pipes in on every render. Falls back to `.output_style` and the camelCase variants for forward compatibility.

**Disable anytime** with `/statusline-output-style off`.

Run this command via Bash:

~/.claude/statusline/switch-output-style.sh $ARGUMENTS

Report the output to the user.
