Toggle the merge-conflicts marker in the statusline. Pass "on"/"true" to enable or "off"/"false" to disable. Toggles if no argument given. Default is on.

When the repo has unresolved merge conflicts, a red `!N` appears next to the existing `~` / `+` / `?` dirty indicators, where N is the number of conflicting paths. Hidden when there are no conflicts.

**How it works**
- Runs `git diff --name-only --diff-filter=U` and counts the lines. Adds one extra git invocation per render.

**Disable anytime** with `/statusline-conflicts off`.

Run this command via Bash:

~/.claude/statusline/switch-conflicts.sh $ARGUMENTS

Report the output to the user.
