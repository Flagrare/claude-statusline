# claude-statusline

You're mid-session, deep in a refactor, and Claude stops responding. Was that the rate limit? How much context is left? You scroll up trying to remember which model you're on. The built-in status bar says "claude-sonnet-4-6" and nothing else.

This replaces it with everything you actually need to see at a glance:

```
claude-sonnet-4-6  │  🧠  high  │  📂 myrepo  🌿 main ~+ ↑2  │  5h:42% 🔥 [1h20m]  │  7d:8% 🍃 [3d4h]  │  ctx: [████░░░░░░] 38%
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
| Sonnet / Opus weekly | **Opt-in** per-model weekly cap, separate from the combined 7-day limit. Anthropic enforces a Sonnet-specific weekly limit on Pro/Max plans (and Opus too on Max). Enable with `/statusline-sonnet` — see [Per-model usage](#per-model-usage-opt-in) below. |
| Session cost | Estimated spend for the current session, calculated from the session JSONL file using Anthropic's published pricing. **Opt-in** — off by default. Set `SHOW_COST=true` in `.statusline.conf` (API plan users only; Pro/Max/Teams users don't need this) |
| Context window | A 10-block progress bar — green below 50%, yellow to 70%, red above — so you know when compaction is coming |

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Flagrare/claude-statusline/main/install.sh)
```

The installer checks for `jq` (the only hard dependency), offers to install it if missing, asks whether you want emoji or Nerd Font icons, and wires up `~/.claude/settings.json`. Restart Claude Code after installing.

Files are placed in `~/.claude/statusline/` and slash commands in `~/.claude/commands/`. No git clone required.

## Icon modes

Four rendering modes, switchable at any time without restarting:

| Mode | What renders | When to use |
|------|-------------|-------------|
| **emoji** (default) | 🧠 🔥 🍃 ⚡️ 📂 🌿 | The colorful default. Works in most modern terminals. Some terminals (notably Warp with its default font) render emoji at width 1, making them look tiny — use `unicode` instead. |
| **nerd** | Nerd Font PUA glyphs | Crisper single-width icons, but your terminal font must be set to a [Nerd Font](https://www.nerdfonts.com/) (JetBrainsMono Nerd Font, FiraCode Nerd Font, etc.) or they'll render as tofu. |
| **unicode** | Geometric Unicode (`≫ ∼ ≡ ※ ◉ ├ ▴ ▾`) | All text-presentation symbols (no emoji VS16 selector), so they render at proper monospace width even in terminals that mis-size emoji. **Recommended for Warp.** |
| **ascii** | Pure 7-bit ASCII (`!! ~~ == [*] [D] \|- ^ v`) | Maximum compatibility — works in any terminal, including non-UTF8 environments. Color still does the visual work for rate limits. |

Switch via slash command in Claude Code (cycles `emoji → nerd → unicode → ascii → emoji` with no arg):

```
/statusline-icons          # cycle to next mode
/statusline-icons nerd     # set explicitly
/statusline-icons emoji
/statusline-icons unicode
/statusline-icons ascii
```

The change takes effect on the next status bar refresh.

## Per-model usage (opt-in)

Claude Code's statusline JSON only exposes the combined 7-day rate limit. But on Pro/Max plans Anthropic enforces a **separate Sonnet weekly cap** (and an Opus weekly cap on Max) — visible in `/usage` but not in the status bar. This package fills that gap.

Enable with:

```
/statusline-sonnet        # toggle
/statusline-sonnet on
/statusline-sonnet off
```

Once enabled you'll see extra segments:

```
... │ 7d:96% 🔥 [4d15h] │ sonnet:12% 🍃 [11h13m] │ ...
```

### How it works

A small background poller (`usage-poller.sh`) calls `https://api.anthropic.com/api/oauth/usage` every ~5 minutes using the OAuth token Claude Code stores for its own `/usage` command — the same endpoint, no third parties. The response is cached at `~/.claude/.statusline-usage-cache.json` and the statusline reads from the cache on every render.

The Opus segment only appears for users whose plan exposes a separate Opus quota; for everyone else only `sonnet:` shows.

### macOS keychain prompt

The first time the poller runs, macOS will show:

> *claude-statusline wants to use your confidential information stored in 'Claude Code-credentials'.*

Click **Always Allow** so you don't see it again. The token never leaves your machine except in the request to `api.anthropic.com`.

### When it does nothing

- API plan users — the endpoint returns `null` for these fields, so no extra segments render.
- Free plan users — same as above.
- Token expired — the poller silently waits; Claude Code refreshes the keychain entry on its next API call and the next poll picks it up.

## Slash commands

Four Claude Code slash commands are available after install:

| Command | What it does |
|---------|-------------|
| `/statusline-icons` | Toggles between emoji and nerd mode. Pass a mode name to set directly: `/statusline-icons nerd` |
| `/statusline-cost` | Toggles session cost display. Pass `on`/`off` to set directly. API plan users only. |
| `/statusline-sonnet` | Toggles the per-model weekly usage segment (Sonnet + Opus). Pass `on`/`off` to set directly. Pro/Max only. |
| `/statusline-update` | Pulls the latest version from GitHub. Re-downloads all files, preserves your config. |

## Requirements

| Dependency | Purpose | Required? |
|-----------|---------|-----------|
| [`jq`](https://jqlang.github.io/jq/) | Parses the JSON that Claude Code pipes to the script each turn | Yes — installer offers to install it |
| `python3` or `jq` | Edits `settings.json` during install | One of them — both ship with macOS and most Linux distros |
| [Nerd Font](https://www.nerdfonts.com/) | Only needed if you choose `nerd` icon mode | No |

## Update

```bash
/statusline-update
```

Or manually: `bash <(curl -fsSL https://raw.githubusercontent.com/Flagrare/claude-statusline/main/update.sh)`

## Uninstall

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Flagrare/claude-statusline/main/uninstall.sh)
```

This removes the `statusLine` key from `~/.claude/settings.json`, deletes `~/.claude/statusline/`, and removes the slash command files.

## License

MIT
