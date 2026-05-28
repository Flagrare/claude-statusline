Toggle the git diff stats display in the statusline. Pass "on"/"true" to enable or "off"/"false" to disable. Toggles if no argument given.

Adds `+N` (green) and `-N` (red) totals for inserted and deleted lines across both staged and unstaged changes, parsed from `git diff --shortstat`. Hidden when the working tree is clean.

**How it works**
- Runs `git diff --shortstat` and `git diff --cached --shortstat`, sums the insertion/deletion counts. One extra git invocation per render when the tree is dirty.

**Disable anytime** with `/statusline-git-diff-stats off`.

Run this command via Bash:

~/.claude/statusline/switch-git-diff-stats.sh $ARGUMENTS

Report the output to the user.
