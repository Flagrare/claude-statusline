# claude-statusline

A custom status bar for [Claude Code](https://claude.ai/code) that shows model, thinking level, git context, rate limits, and context window usage at a glance.

```
claude-sonnet-4-6  │  🎓  high  │  myrepo  main  │  5h:42% [1h20m]  │  7d:18% [2d4h]  │  ctx: [████░░░░░░] 38%
```

## What it shows

| Segment | Description |
|---------|-------------|
| Model name | Active Claude model |
| 🎓 Thinking level | Effort level: `low` · `medium` · `high` · `xhigh` · `max`, color-coded |
| Git repo + branch | Repo name and current branch (when inside a git repo) |
| 5h rate limit | 5-hour token usage % with countdown and velocity indicator |
| 7d rate limit | 7-day token usage % with countdown and velocity indicator |
| Context window | Visual bar showing how full the context is, color shifts green → yellow → red |

## Requirements

- [Claude Code](https://claude.ai/code) 2.x+
- [`jq`](https://jqlang.github.io/jq/) (`apt install jq` / `brew install jq`)
- A [Nerd Font](https://www.nerdfonts.com/) with Font Awesome 4 icons (e.g. JetBrainsMono Nerd Font, FiraCode Nerd Font)

## Install

```bash
git clone https://github.com/flagrare/claude-statusline
cd claude-statusline
bash install.sh
```

Then restart Claude Code.

## Uninstall

Remove the `statusLine` key from `~/.claude/settings.json`:

```bash
jq 'del(.statusLine)' ~/.claude/settings.json > /tmp/s.json && mv /tmp/s.json ~/.claude/settings.json
```
