Toggle the account badge in the statusline. Pass "on"/"true" to enable or "off"/"false" to disable. Toggles if no argument given.

Adds a `👤 Max · example.com` segment at the start of the top row: the plan and email domain of the login this session bills to. Useful when you keep more than one account (for example a personal subscription and a company Enterprise seat) and want to see which one a session is on.

**How it reads**
- Orange: an individual plan (Pro, Max, Ultra). Blue: an organization plan (Team, Enterprise) or a cloud provider (Bedrock, Vertex, Foundry).
- Red with ⚠️: the login's email domain isn't in `ACCOUNT_WORK_DOMAINS`. Set it in `~/.claude/statusline/.statusline.conf`, comma-separated with no spaces, e.g. `ACCOUNT_WORK_DOMAINS=example.com,example.org`. Leave it unset to skip the check.

**How it works**
- Reads the login Claude Code saved in `~/.claude.json` (or `$CLAUDE_CONFIG_DIR/.claude.json`), so it updates after a `/login` mid-session. No network calls.

**Disable anytime** with `/statusline-account off`.

Run this command via Bash:

~/.claude/statusline/switch-account.sh $ARGUMENTS

Report the output to the user.
