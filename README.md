# claude-statusline

You're mid-session, deep in a refactor, and Claude stops responding. Was that the rate limit? How much context is left? You scroll up trying to remember which model you're on. The built-in status bar says "claude-sonnet-4-6" and nothing else.

This replaces it with everything you actually need to see at a glance:

```
claude-sonnet-4-6  │  🧠  high  │  📂 myrepo  🌿 main ↑2  │  5h:42% 🔥 [1h20m]  │  7d:8% 🍃 [3d4h]  │  ctx: [████░░░░░░] 38%
```

Rate limits, context window fullness, thinking effort, git branch — color-coded and updated every turn.

Nerd Font mode:
<img width="1270" height="159" alt="Nerd Font mode screenshot" src="https://github.com/user-attachments/assets/43709554-db4f-4d25-92c4-fab5fb6923d7" />

Emoji mode:
<img width="1470" height="162" alt="Emoji mode screenshot" src="https://github.com/user-attachments/assets/3741a770-54be-4116-b1c7-295d3f39964c" />

## What each segment tells you

| Segment | What you see |
|---------|-------------|
| Model name | Which model is active for this session |
| 🧠 Thinking level | Current effort setting (`low` through `max`), color-coded gray to orange as it increases |
| Git repo + branch | Repo name and current branch. `~` (yellow) unstaged changes, `+` (green) staged, `?` (gray) untracked files — these stack, so `~+` means you have both. `↑N` (green) when you have commits to push, `↓N` (yellow) when commits are waiting to pull — reads cached remote refs, no network hit |
| 5h / 7d rate limits | How much of your token budget you've used, how long until it resets, and whether you're burning through it faster than the clock would suggest (🔥 burning fast, ⚡️ on track, 🍃 relaxed) |
| Session cost | Estimated spend for the current session, calculated from the session JSONL file using Anthropic's published pricing. **Opt-in** — off by default. Set `SHOW_COST=true` in `.statusline.conf` (API plan users only; Pro/Max/Teams users don't need this) |
| Context window | A 10-block progress bar — green below 50%, yellow to 70%, red above — so you know when compaction is coming |

## Install

```bash
git clone https://github.com/Flagrare/claude-statusline
cd claude-statusline
bash install.sh
```

The installer checks for `jq` (the only hard dependency), offers to install it if missing, asks whether you want emoji or Nerd Font icons, and wires up `~/.claude/settings.json`. Restart Claude Code after installing.

Since the script runs from the cloned directory, pulling new commits updates it in place — no reinstall needed.

## Icon modes

Two rendering modes, switchable at any time without restarting:

| Mode | What renders | When to use |
|------|-------------|-------------|
| **emoji** (default) | 🧠 🔥 🍃 ⚡️ 📂 🌿 | Works in every modern terminal. Use this if you're on Warp or haven't configured a Nerd Font. |
| **nerd** | Nerd Font PUA glyphs | Crisper single-width icons, but your terminal font must be set to a [Nerd Font](https://www.nerdfonts.com/) (JetBrainsMono Nerd Font, FiraCode Nerd Font, etc.) or they'll render as invisible. |

Switch from the shell:

```bash
./switch-icons.sh        # toggle
./switch-icons.sh emoji  # set explicitly
./switch-icons.sh nerd
```

The change takes effect on the next status bar refresh — no restart needed.

## Slash commands

Two Claude Code slash commands ship with the repo (available after install and a session restart):

| Command | What it does |
|---------|-------------|
| `/statusline-icons` | Toggles between emoji and nerd mode. Pass a mode name to set directly: `/statusline-icons nerd` |
| `/statusline-update` | Pulls the latest version from GitHub. Equivalent to running `git pull` in the install directory. |

## Requirements

| Dependency | Purpose | Required? |
|-----------|---------|-----------|
| [`jq`](https://jqlang.github.io/jq/) | Parses the JSON that Claude Code pipes to the script each turn | Yes — installer offers to install it |
| `python3` or `jq` | Edits `settings.json` during install | One of them — both ship with macOS and most Linux distros |
| [Nerd Font](https://www.nerdfonts.com/) | Only needed if you choose `nerd` icon mode | No |

## Uninstall

```bash
cd claude-statusline
bash uninstall.sh
```

This removes the `statusLine` key from `~/.claude/settings.json` and leaves everything else intact. Delete the cloned directory afterwards if you want a clean slate.

## License

MIT
