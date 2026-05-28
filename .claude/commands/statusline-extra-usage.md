Toggle the extra-usage (overage) segment in the statusline. Pass "on"/"true" to enable or "off"/"false" to disable. Toggles if no argument given.

When pay-as-you-go overage is enabled on your Anthropic account, this surfaces the running spend (e.g. `+$12.50 (25%)`) so you can see how much overage you've accrued without leaving Claude Code. Hidden when overage isn't enabled.

**How it works**
- Reads `extra_usage.is_enabled`, `utilization`, `used_credits`, and `currency` from `~/.claude/.statusline-usage-cache.json` — the same background-polled cache used by `/statusline-sonnet`. No extra API calls.
- Skipped entirely when `is_enabled` is false or utilization is null.

**Disable anytime** with `/statusline-extra-usage off`.

Run this command via Bash:

~/.claude/statusline/switch-extra-usage.sh $ARGUMENTS

Report the output to the user.
