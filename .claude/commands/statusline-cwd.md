Toggle the CWD display in the statusline. Pass "on"/"true" to enable or "off"/"false" to disable. Toggles if no argument given.

When you're outside any git repo, shows a fish-style abbreviated path (e.g. `~/D/c/claude-statusline`) so you can still see where you are. Inside a git repo, the existing repo-name display already covers it, so this segment stays hidden to avoid duplication.

**Disable anytime** with `/statusline-cwd off`.

Run this command via Bash:

~/.claude/statusline/switch-cwd.sh $ARGUMENTS

Report the output to the user.
