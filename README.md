# claude-statusline

Claude Code's built-in status bar shows the model name and not much else. This replaces it with a bar that tells you what actually matters during a session: how hard the model is thinking, how close you are to rate limits (and whether you're burning them faster than expected), what repo and branch you're in, and how full the context window is.

```
claude-sonnet-4-6  │  🧠  high  │  📂 myrepo  🌿 main  │  5h:42% 🔥 [1h20m]  │  7d:8% 🍃 [3d4h]  │  ctx: [████░░░░░░] 38%
```

*(Colors render in terminal: green, yellow, red as limits approach.)*

<img width="1270" height="159" alt="Screenshot 2026-05-22 095608" src="https://github.com/user-attachments/assets/43709554-db4f-4d25-92c4-fab5fb6923d7" />

## What it shows

| Segment | What it tells you |
|---------|-------------------|
| Model name | Active model for the session |
| 🧠 Thinking level | Effort level (`low` / `medium` / `high` / `xhigh` / `max`), color-coded |
| Git repo + branch | Repo name and current branch when inside a git repo |
| 5h rate limit | Usage % of your 5-hour token budget, countdown to reset, velocity glyph (🔥 burning fast / ⚡️ on track / 🍃 relaxed) |
| 7d rate limit | Same for your 7-day budget |
| Context window | 10-block bar showing how full the context is; green < 50%, yellow to 70%, red above |

## Install

```bash
git clone https://github.com/Flagrare/claude-statusline
cd claude-statusline
bash install.sh
```

The installer will:
- Check for required dependencies and offer to install any that are missing
- Ask which icon mode you prefer (emoji or Nerd Font)
- Configure `~/.claude/settings.json` to point to the statusline script

Restart Claude Code after installing.

## Icon modes

The statusline supports two icon modes:

| Mode | Icons | Requirement |
|------|-------|-------------|
| **emoji** (default) | 🧠 🔥 🍃 ⚡️ 📂 🌿 | Works in all modern terminals |
| **nerd** | Nerd Font glyphs (PUA) | Terminal font must be set to a [Nerd Font](https://www.nerdfonts.com/) |

Switch between them at any time:

```bash
# Toggle
./switch-icons.sh

# Set explicitly
./switch-icons.sh emoji
./switch-icons.sh nerd
```

If you have Claude Code's slash commands available, use `/statusline-icons` or `/statusline-icons nerd`.

The change takes effect on the next status bar refresh (no restart needed).

## Requirements

| Dependency | Purpose | Required? |
|-----------|---------|-----------|
| [`jq`](https://jqlang.github.io/jq/) | JSON parsing at runtime | Yes (installer will offer to install) |
| `python3` or `jq` | Editing settings.json during install | One of them (both ship with most systems) |
| [Nerd Font](https://www.nerdfonts.com/) | Only needed for `nerd` icon mode | No (emoji mode works without it) |

## Uninstall

```bash
cd claude-statusline
bash uninstall.sh
```

Or manually remove the `"statusLine"` key from `~/.claude/settings.json`.

## License

MIT
