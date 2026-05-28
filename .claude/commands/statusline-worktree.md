Toggle the worktree marker in the statusline. Pass "on"/"true" to enable or "off"/"false" to disable. Toggles if no argument given. Default is on.

When you're inside a linked git worktree (created with `git worktree add ...`), the folder icon next to the repo name swaps from the regular folder glyph to a worktree-specific one. In the main checkout it renders identically to before.

**How it works**
- Compares `git rev-parse --git-common-dir` to `--git-dir`. They differ only when you're in a linked worktree.
- The icon used in worktree mode depends on the current icon set: 🌳 (emoji), the code-fork glyph from Nerd Font, `⎇` (unicode), or `[wt]` (ascii).

**Disable anytime** with `/statusline-worktree off`.

Run this command via Bash:

~/.claude/statusline/switch-worktree.sh $ARGUMENTS

Report the output to the user.
