Open the interactive claude-statusline configurator — pick an icon mode and tick the features you want, all in one screen. Same checklist the Advanced installer uses. The per-feature commands (`/statusline-pr`, `/statusline-cost`, …) stay for quick single flips; this is the "show me everything" view.

**Important:** this configurator is **interactive** — it reads keyboard input to let the user tick boxes. It therefore must run in the user's own terminal, not through a captured Bash call (which has no TTY and would read EOF, saving no changes).

So do NOT run it yourself via a normal Bash tool call. Instead, tell the user to run it directly in their session:

    ! ~/.claude/statusline/configure.sh

The `!` prefix runs it interactively in their terminal so they can answer the prompts. When they finish, the new config takes effect on the next status-bar refresh. If the `!` prefix doesn't give them an interactive prompt, have them run `~/.claude/statusline/configure.sh` in a regular terminal instead.
