Toggle the prompt-cache segment in the statusline. Pass "on"/"true" to enable or "off"/"false" to disable. Toggles if no argument given.

Adds `🧊 94% · warm 3m` next to the context bar: the share of input read from the prompt cache this session, and how long until the cached conversation goes cold. It turns yellow in the last minute. `🧊 94% · cold` means the next turn re-reads the whole conversation at full price, so it's a good moment to `/compact` or start fresh if you were about to step away anyway.

**How it works**
- Reads `prompt_cache` from the status data Claude Code sends (v2.1.251 or later). Hidden when caching isn't reported. No network calls.

**Disable anytime** with `/statusline-cache off`.

Run this command via Bash:

~/.claude/statusline/switch-cache.sh $ARGUMENTS

Report the output to the user.
