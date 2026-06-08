Toggle the context warning, or set its token threshold. Pass "on"/"off" to toggle visibility, or a token count (e.g. `150000`, `150k`, `2m`) to set the threshold. Toggles if no argument given. Default is on at 200000 tokens.

A red `⚠ >Nk` badge appears on the top row, just after the context bar, once the context reaches `CONTEXT_WARNING_TOKENS` tokens (default `200000` — the long-context pricing tier on the 1M models). The label tracks the threshold automatically: `200000 → >200k`, `150000 → >150k`, `1500000 → >1.5M`. Hidden below the threshold, so it only speaks up when it matters.

**How it works**
- Reads `.context_window.total_input_tokens` from the status JSON Claude Code sends on stdin and compares it to your threshold. Falls back to the `exceeds_200k_tokens` boolean if the token count isn't provided. No extra process, no network.

**Examples**
- `/statusline-context-warning 150k` — warn once the context passes 150,000 tokens.
- `/statusline-context-warning off` — hide it entirely.

Run this command via Bash:

~/.claude/statusline/switch-context-warning.sh $ARGUMENTS

Report the output to the user.
