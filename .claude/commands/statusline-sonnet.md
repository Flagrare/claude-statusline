Toggle the per-model weekly usage indicator in the statusline (Sonnet, plus Opus when applicable). Pass "on"/"true" to enable or "off"/"false" to disable. Toggles if no argument given.

Adds a `sonnet:N% [resets]` segment showing Anthropic's per-model weekly cap, which is enforced separately from the combined 7-day limit. Useful for Pro/Max plan users who want to know how much Sonnet-specific quota they have left.

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
