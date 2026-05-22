# claude-statusline

Claude Code's built-in status bar shows the model name and not much else. This replaces it with a bar that tells you what actually matters during a session: how hard the model is thinking, how close you are to rate limits (and whether you're burning them faster than expected), what repo and branch you're in, and how full the context window is.

```
claude-sonnet-4-6  │  🎓  high  │  myrepo  main  │  5h:42% 🔥 [1h20m]  │  7d:8% 🍃 [3d4h]  │  ctx: [████░░░░░░] 38%
```

*(Colors render in terminal — green → yellow → red as limits approach.)*

<img width="1270" height="159" alt="Screenshot 2026-05-22 095608" src="https://github.com/user-attachments/assets/43709554-db4f-4d25-92c4-fab5fb6923d7" />

## What it shows

| Segment | What it tells you |
|---------|-------------------|
| Model name | Active model for the session |
| 🎓 Thinking level | Effort level (`low` · `medium` · `high` · `xhigh` · `max`), color-coded gray → cyan → green → yellow → orange |
| Git repo + branch | Repo name and current branch when inside a git repo |
| 5h rate limit | Usage % of your 5-hour token budget, with time until reset and a velocity glyph (🔥 burning fast · ⚡ on track · 🍃 relaxed) |
| 7d rate limit | Same for your 7-day budget |
| Context window | 10-block bar showing how full the context is; green below 50%, yellow to 70%, red above |

## Requirements

- [Claude Code](https://claude.ai/code) 2.x+
- [`jq`](https://jqlang.github.io/jq/) — JSON parsing (`apt install jq` / `brew install jq`)
- `bc` — float arithmetic (usually pre-installed; `apt install bc` if missing)
- A [Nerd Font](https://www.nerdfonts.com/) with **Font Awesome 4** icons — e.g. JetBrainsMono Nerd Font, FiraCode Nerd Font. FA5-only fonts will show placeholder squares for the icons.

## Install

```bash
git clone https://github.com/flagrare/claude-statusline
cd claude-statusline
bash install.sh
```

Restart Claude Code. The status bar updates automatically each turn.

## Uninstall

```bash
jq 'del(.statusLine)' ~/.claude/settings.json > /tmp/s.json && mv /tmp/s.json ~/.claude/settings.json
```

## License

MIT
