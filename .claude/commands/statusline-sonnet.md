Toggle the per-model weekly usage indicator in the statusline (currently Fable; follows whichever model your plan caps separately). Pass "on"/"true" to enable or "off"/"false" to disable. Toggles if no argument given.

Adds a segment such as `fable:N% [resets]` for each model with its own weekly cap, which Anthropic enforces separately from the combined 7-day limit. Useful for Pro/Max plan users who want to know how much model-specific quota they have left. The command keeps its `sonnet` name for compatibility with existing configs.

**Requirements**
- Claude Pro or Max plan. API plan users will see no change.

**How it works**
- A background poller (`usage-poller.sh`) calls `https://api.anthropic.com/api/oauth/usage` every ~5 minutes using the OAuth token Claude Code stores for its own `/usage` command. The response is cached at `~/.claude/.statusline-usage-cache.json`.
- This is the same endpoint Claude Code's `/usage` already uses — no third-party services are contacted.

**macOS keychain prompt**
- The first time the poller runs, macOS will show a dialog: *"claude-statusline wants to use your confidential information stored in 'Claude Code-credentials'."* Click **Always Allow** so you don't see it again.

**Disable anytime** with `/statusline-sonnet off`.

Run this command via Bash:

~/.claude/statusline/switch-sonnet.sh $ARGUMENTS

Report the output to the user.
