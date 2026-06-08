# claude-statusline

You're mid-session, deep in a refactor, and Claude stops responding. Was that the rate limit? How much context is left? You scroll up trying to remember which model you're on. The built-in status bar says "claude-sonnet-4-6" and nothing else.

This replaces it with everything you actually need to see at a glance. The essentials — model, thinking effort, git branch, rate limits, context — sit together on the top row; anything optional (session meta, live speed, cost) drops to a second row only when you enable it:

```
claude-sonnet-4-6  │  🧠 high  │  📂 myrepo  🌿 main ~+  │  5h:42% 🔥 [1h20m]  │  7d:8% 🍃 [3d4h]  │  ctx: [████░░░░░░] 38%
💨 142↓ 87↑/s  │  style:learning  │  🆔 a1b2c3  │  v2.6.0  │  $1.23
```

Rate limits, context window fullness, thinking effort, git branch — color-coded and updated every turn. Each row is a continuous, pipe-separated group rendered flush-left; when a row is wider than your terminal it wraps onto another line rather than truncating. See [Layout & width](#layout--width).

<!-- STALE: screenshots predate the v2.6.0 continuous-row layout. Re-shoot before release. -->
Nerd Font mode:
<img width="1270" height="159" alt="Nerd Font mode screenshot" src="https://github.com/user-attachments/assets/43709554-db4f-4d25-92c4-fab5fb6923d7" />

Emoji mode:
<img width="1470" height="162" alt="Emoji mode screenshot" src="https://github.com/user-attachments/assets/3741a770-54be-4116-b1c7-295d3f39964c" />

## What each segment tells you

| Segment | What you see |
|---------|-------------|
| Model name | Which model is active for this session |
| 🧠 Thinking level | Current effort setting (`low` through `max`), color-coded gray to orange as it increases |
| ⚡ Fast mode | A `⚡ fast` badge on the top row while Claude Code's Fast mode is active. Auto-hides otherwise. **On by default** — toggle with `/statusline-fast-mode`. |
| Git repo + branch | Repo name and current branch. `~` (yellow) unstaged changes, `+` (green) staged, `?` (gray) untracked files — these stack, so `~+` means you have both. `↑N` (green) when you have commits to push, `↓N` (yellow) when commits are waiting to pull — reads cached remote refs, no network hit. When you're in a linked worktree, the folder icon swaps to a worktree-specific glyph (toggleable with `/statusline-worktree`). `!N` (red) appears next to the dirty indicators when there are unresolved merge conflicts (`/statusline-conflicts`). |
| Git diff stats | **Opt-in** — `+N` green / `-N` red insertion and deletion totals across staged + unstaged. Enable with `/statusline-git-diff-stats`. |
| PR link | **Opt-in** — clickable `PR#1234` (the whole label is an OSC8 hyperlink) when the current branch has an associated GitHub PR. Color-coded by state (open/draft/merged/closed). Requires `gh` CLI. Cache-only render, never blocks. Enable with `/statusline-pr`. |
| Output style | **Opt-in** — dim `style:explanatory` / `style:learning` label on the second row. Enable with `/statusline-output-style`. |
| Session ID | **Opt-in** — id-tagged 6-char prefix of the session UUID (`🆔 a1b2c3`). Enable with `/statusline-session-id`. |
| Claude Code version | **Opt-in** — trailing `vX.Y.Z` (the host app's version). Enable with `/statusline-claude-version`. |
| CWD (outside git) | **Opt-in** — fish-style abbreviated path (`~/D/c/claude-statusline`) when you're outside any git repo. Inside a repo the existing repo name covers it. Enable with `/statusline-cwd`. |
| Extra usage | **Opt-in** — pay-as-you-go overage spend (`+$12.50 (25%)`) when enabled on your account. Auto-hides otherwise. Enable with `/statusline-extra-usage`. |
| 5h / 7d rate limits | How much of your token budget you've used, how long until it resets, and whether you're burning through it faster than the clock would suggest (🔥 burning fast, ⚡️ on track, 🍃 relaxed) |
| Sonnet / Opus weekly | **Opt-in** per-model weekly cap, separate from the combined 7-day limit. Anthropic enforces a Sonnet-specific weekly limit on Pro/Max plans (and Opus too on Max). Enable with `/statusline-sonnet` — see [Per-model usage](#per-model-usage-opt-in) below. |
| Session cost | Estimated spend for the current session, calculated from the session JSONL file using Anthropic's published pricing. **Opt-in** — off by default. Set `SHOW_COST=true` in `.statusline.conf` (API plan users only; Pro/Max/Teams users don't need this) |
| ⏱ Session duration | **Opt-in** — how long the current session has been running, from the first message timestamp in the JSONL. Enable with `/statusline-session-duration` |
| 💨 Token speed | **Opt-in** — last assistant turn's input↓ / output↑ tokens per second. Useful for spotting tool-call latency vs. generation speed. Enable with `/statusline-token-speed` |
| Context window | A 10-block progress bar — green below 50%, yellow to 70%, red above — so you know when compaction is coming |
| ⚠ >200k context | A red `⚠ >200k` badge once the session crosses the 200k-token long-context pricing threshold. Hidden below it. **On by default** — toggle with `/statusline-context-warning`. |
| 🔄 Compaction counter | **Opt-in** — appears next to the context bar after one or more auto-compactions in the current session. Enable with `/statusline-compaction` |

## Layout & width

The statusline renders as up to two rows, split by importance rather than by alignment:

- **Row 1 — the core.** Model, thinking effort, fast-mode badge, git repo/branch, the 5h / 7d / per-model rate limits, the context bar (with compaction counter), and the >200k warning. Everything you almost always want.
- **Row 2 — the extras.** Token speed, session duration, CWD, output style, session ID, version, extra usage, session cost. Each is opt-in, and the whole row is suppressed when none are enabled — so a lean config is a single line with no trailing blank.

Within a row, segments are a continuous group separated by ` │ ` and rendered flush-left. There's no left/right spread: the first segment starts at column zero and the rest follow.

When a row is wider than your terminal, it **wraps** onto another line at a ` │ ` boundary rather than truncating at the edge — so nothing important falls off-screen, it just flows downward. (A single segment wider than the whole terminal still takes its own line; there's nothing smaller to break on.)

Width is detected automatically in this order: `COLS` (config) → `$COLUMNS` → `tput cols` → `80`. If wrapping happens too early or too late, pin it explicitly in `.statusline.conf`:

```
COLS=160
```

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

### Icons look small, washed out, or wrong

Almost always a **mode mismatch**, not a bug — the script only emits a codepoint; the terminal and font decide how it looks.

- **Nerd-mode icons look tiny / monochrome next to big text.** That's nerd mode working as designed: Nerd Font glyphs are single-cell, monochrome symbols (e.g. the effort icon is `nf-fa-graduation_cap`, not a 🧠 emoji). If you wanted big and colorful, switch with `/statusline-icons emoji`. If you wanted crisp-but-flat, `/statusline-icons unicode` renders at full text size with no font dependency.
- **Nerd-mode icons render as blank boxes (tofu).** Your terminal font isn't a Nerd Font. Set it to a patched build — e.g. in Ghostty, `font-family = "JetBrainsMono Nerd Font"`. Watch the exact name: `JetBrainsMono NFM` is *not* a valid family; the real one is `JetBrainsMono Nerd Font` (or `… Nerd Font Mono`).
- **Nerd-mode icons render but feel too small even with the right font.** Some terminals shrink Private-Use glyphs to one cell. Ghostty exposes `adjust-icon-height` (try `115%`) to nudge them up. This is a terminal setting; the statusline can't scale glyphs.
- **Emoji look tiny / width-1 (notably Warp).** The terminal is rendering emoji in text presentation. Use `/statusline-icons unicode` instead.

**On Ghostty specifically** — two things are easy to conflate, and only one is font-dependent:

- **Whether glyphs render at all (tofu vs. glyph) — font-dependent.** Ghostty ships a built-in symbols-only Nerd Font, so with `font-family` *unset*, nerd glyphs always render. If someone sets `font-family` to a name that doesn't resolve (e.g. `JetBrainsMono NFM` instead of `JetBrainsMono Nerd Font Mono`), glyphs fall back to tofu until the exact name is fixed.
- **How big the glyphs are — *not* font-dependent on Ghostty 1.2.0+.** Ghostty auto-resizes Nerd Font symbols to the cell the same way the official patcher does, whether they come from the built-in symbols or an explicit patched font. We verified this live on Ghostty 1.3.1: forcing `font-family = "…Nerd Font Mono"` changed the icon size *not at all*. So a patched font buys you nothing for size — Ghostty's docs say as much.

So if your nerd icons feel small, it's almost never the font — it's simply that **cell-sized monochrome glyphs look smaller than big color emoji**, which is the nature of nerd mode. Want bigger and colorful? `/statusline-icons emoji`. Want to keep nerd but nudge the scale? `adjust-icon-height = 115%`. (Only on **Ghostty < 1.2.0**, which lacked auto-resize, did a non-Mono `…Nerd Font` build actually render larger — there, the fix is to upgrade Ghostty.)

When in doubt, cycle through the four modes with `/statusline-icons` and keep whichever looks right in your terminal — there's no single correct answer across terminals and fonts.

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

## JSONL signals (opt-in)

Three extra segments are derived from the current session's transcript JSONL under `~/.claude/projects/<encoded-cwd>/`. All three default to off and have their own toggle.

| Command | Segment | What it shows |
|---------|---------|--------------|
| `/statusline-session-duration` | `⏱ 1h23m` | Elapsed time since the first message in the active session |
| `/statusline-token-speed` | `💨 142↓ 87↑/s` | Last assistant turn's input/output tokens per second |
| `/statusline-compaction` | `🔄2` next to the context bar | Counts auto-compaction events detected during the session |

All three are pure local reads — no network calls. Token speed and session duration cost one bounded read (`head -1` + `tail -200`) of the JSONL on each render; compaction maintains a tiny per-session state file under `~/.claude/.statusline-state/`.

## Slash commands

Sixteen Claude Code slash commands are available after install:

| Command | What it does |
|---------|-------------|
| `/statusline-icons` | Toggles between emoji and nerd mode. Pass a mode name to set directly: `/statusline-icons nerd` |
| `/statusline-cost` | Toggles session cost display. Pass `on`/`off` to set directly. API plan users only. |
| `/statusline-sonnet` | Toggles the per-model weekly usage segment (Sonnet + Opus). Pass `on`/`off` to set directly. Pro/Max only. |
| `/statusline-session-duration` | Toggles the session duration segment. Pass `on`/`off` to set directly. |
| `/statusline-token-speed` | Toggles the token speed segment. Pass `on`/`off` to set directly. |
| `/statusline-compaction` | Toggles the compaction counter. Pass `on`/`off` to set directly. |
| `/statusline-git-diff-stats` | Toggles the `+N -N` diff totals next to the dirty indicators. Off by default. |
| `/statusline-pr` | Toggles the clickable GitHub PR number for the current branch. Off by default; requires `gh`. |
| `/statusline-worktree` | Toggles the worktree-specific folder icon when inside a linked git worktree. **On by default.** |
| `/statusline-conflicts` | Toggles the `!N` red marker for unresolved merge conflicts. **On by default.** |
| `/statusline-fast-mode` | Toggles the `⚡ fast` badge shown while Fast mode is active. **On by default**; auto-hides when Fast mode is off. |
| `/statusline-context-warning` | Toggles the `⚠ >200k` badge shown past the 200k-token threshold. **On by default**; auto-hides below it. |
| `/statusline-output-style` | Toggles the `style:…` label on the second row. Off by default. |
| `/statusline-session-id` | Toggles the trailing 6-char session ID. Off by default. |
| `/statusline-claude-version` | Toggles the trailing Claude Code (host app) version badge. Off by default. |
| `/statusline-cwd` | Toggles the fish-style abbreviated path (shown only when outside any git repo). Off by default. |
| `/statusline-extra-usage` | Toggles the pay-as-you-go overage segment. Off by default; auto-hides when not enabled on your account. |
| `/statusline-version` | Prints the installed claude-statusline version and checks GitHub for a newer one. |
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
