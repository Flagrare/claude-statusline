Toggle the daily token total in the statusline. Pass "on"/"true" to enable or "off"/"false" to disable. Toggles if no argument given.

Adds a `📊 297.3M today` segment: every token used since local midnight, across all sessions, projects, and subagents.

**What counts**
- Input + output + cache writes + cache reads. Cache reads are usually most of it, so read the number as tokens processed, not tokens billed at the full rate.
- Each API request counts once, even though the session log repeats its usage on one line per content block.

**How it works**
- A background script reads the session logs under `~/.claude/projects/` at most once a minute, only the lines added since its last read, and keeps the running total in `~/.claude/.statusline-state/daily-tokens`.
- The first read of the day can take a few seconds, so the segment shows up on a later render.
- No network calls.

**Disable anytime** with `/statusline-daily-tokens off`.

Run this command via Bash:

~/.claude/statusline/switch-daily-tokens.sh $ARGUMENTS

Report the output to the user.
