# Changelog

## v2.6.0 — 2026-06-08

The top row now holds everything you watch most — model, effort, git, rate limits, context — as one continuous line that wraps instead of truncating.

### Layout

- **Rows**: each row is a single pipe-separated group, flush-left — the old justified left/right split (and its mid-row gap) is gone. Rate limits move up to the top row alongside the context bar; optional session meta drops to a second row that vanishes entirely when you've enabled none of it.
- **Wrapping**: a row wider than the terminal wraps at a ` │ ` boundary instead of truncating at the edge — nothing important runs off-screen.

### New Features

- **`/statusline-fast-mode`**: a `⚡ fast` badge on the top row while Claude Code's Fast mode is active. On by default; auto-hides otherwise.
- **`/statusline-context-warning`**: a red `⚠ >200k` badge once the session crosses the 200k-token long-context pricing threshold. On by default; hidden below it.

### Behaviour

- **Output style**: now a `style:learning` label on the second row (was a bracketed `[learning]` badge next to the model name).
- **Session ID**: now id-tagged — `🆔 a1b2c3` (was a bare 6-char prefix).
- **PR link**: the whole `PR#1234` label is now the clickable hyperlink (was only the number).

---

## v2.5.1 — 2026-05-29

### Behaviour

- **Context bar**: moved to the top row, just before session ID and version — restoring its position as the last status widget. The bottom row now carries only token budgets (rate limits, cost).

---

## v2.5.0 — 2026-05-29

The statusline now renders as two full-width rows instead of one. With every segment enabled, the old single row overflowed and truncated — model name and git branch fought for the same space. Grouping segments into justified rows fixes that and uses the whole terminal width.

### New Features

- **Two-row justified layout**: identity and workspace on top (model, effort, session duration · git, CWD, session ID, version), gauges and budget below (context, token speed · rate limits, extra usage, cost). Each row spreads a left group flush-left and a right group flush-right, so the full terminal width is used and wide segments no longer collide.
- **`COLS` config override**: width auto-detects (`$COLUMNS` → `tput cols` → `80`), but you can pin it in `.statusline.conf` (`COLS=160`) when your terminal isn't detected correctly.

### Behaviour

- On terminals narrower than the content, rows degrade gracefully — the two groups stay separated by at least two spaces rather than wrapping. Session ID and version (least critical) are the first to run off the right edge.

---

## v2.4.0 — 2026-05-28

Five more opt-in segments pull from data the statusline already receives but never displayed — output style, session ID, Claude Code version, current directory (outside git), and pay-as-you-go overage.

### New Features

- **`/statusline-output-style`**: dim `[explanatory]` / `[learning]` badge next to the model name so you can see at a glance which output style is active.
- **`/statusline-session-id`**: trailing 6-character prefix of the session UUID. Useful when juggling multiple sessions in tmux/iTerm splits.
- **`/statusline-version`**: trailing `vX.Y.Z` badge so you can spot when Claude Code has been updated under you.
- **`/statusline-cwd`**: fish-style abbreviated path (`~/D/c/claude-statusline`) when you're outside any git repo. Hidden inside a repo since the repo name already covers it.
- **`/statusline-extra-usage`**: surfaces pay-as-you-go overage spend (`+$12.50 (25%)`) when enabled on your account, color-coded by utilization. Auto-hides when overage isn't active, so leaving it on is safe.

---

## v2.3.0 — 2026-05-28

Four new toggles deepen the git segment with information you previously had to run a command to see. Worktree marker and conflicts indicator default on — both surface state you almost always want to know.

### New Features

- **`/statusline-conflicts`** (default on): adds a red `!N` to the dirty indicators when there are unresolved merge conflicts.
- **`/statusline-worktree`** (default on): folder icon swaps to a worktree-specific glyph when you're inside a linked git worktree, so you can see at a glance that you're not in the main checkout.
- **`/statusline-git-diff-stats`**: adds `+N -N` insertion/deletion totals across staged + unstaged changes.
- **`/statusline-pr`**: adds a clickable `#1234` hyperlink (OSC8) when the current branch has an open GitHub PR. Color-coded by state (open / draft / merged / closed). Requires `gh`. Renders from a 60s background cache, never blocks.

### Behaviour

- Git subprocesses in the statusline now run with `GIT_OPTIONAL_LOCKS=0`, avoiding `.git/index.lock` contention when another git process (Claude Code's own commands, editor integrations) is writing the index concurrently.

---

## v2.2.0 — 2026-05-28

Three new opt-in segments surface signals already sitting in your session transcript — how long the session has been running, how fast the last turn produced tokens, and how many times context auto-compacted. All three read the JSONL directly, default off, and toggle independently.

### New Features

- **`/statusline-session-duration`**: adds a `⏱ 1h23m` segment showing elapsed time since the first message in the current session.
- **`/statusline-token-speed`**: adds a `💨 142↓ 87↑/s` segment showing the last assistant turn's input/output tokens per second. Input rate includes cached tokens.
- **`/statusline-compaction`**: adds a `🔄N` marker next to the context bar after one or more auto-compactions in the session. Hidden when the count is zero.

---

## v2.1.0 — 2026-05-28

A new opt-in status bar segment shows your **per-model weekly quota** — the same Sonnet-specific number Anthropic surfaces in `/usage`, but always visible. Opus too, when your plan tracks it separately. Useful when you're approaching the combined 7-day cap and need to know whether switching models would actually buy you more headroom.

### New Features

- **`/statusline-sonnet`**: toggles the per-model weekly usage segment. Renders `sonnet:N% [resets]` (and `opus:N%` when present) using the same color thresholds and velocity icons as the existing 5h / 7d segments. Off by default.
- **Data source**: a background poller calls Anthropic's `/api/oauth/usage` every ~5 min using the OAuth token Claude Code already stores for `/usage` — same endpoint, no third parties. Cached at `~/.claude/.statusline-usage-cache.json`.
- **macOS first-run**: macOS shows a one-time keychain dialog the first time the poller reads the token. Click "Always Allow".

---

## v2.0.1 — 2026-05-25

### Bug Fixes

- **Session cost**: now appears for usernames containing dots or other
  non-alphanumeric characters. The project-key derivation was only
  replacing `/` with `-`, but Claude Code replaces all special chars.

---

## v2.0.0 — 2026-05-25

Install without git. One curl command gets the statusline running; updates and uninstall work the same way. Existing clone-based installs are migrated automatically on first `/statusline-update`.

### General

- **Install model**: `bash <(curl -fsSL ...)` downloads everything to
  `~/.claude/statusline/` and `~/.claude/commands/`. No git clone, no
  repo directory to maintain.
- **`/statusline-update`**: re-downloads all scripts from GitHub,
  preserving your `.statusline.conf` settings. Detects old clone-based
  installs and migrates config + settings.json pointer automatically.
- **Uninstall**: `bash <(curl ...)` now removes the install directory,
  slash commands, and the settings.json entry in one step.
- **`/statusline-cost`**: new slash command to toggle session cost
  display. Accepts `on`, `off`, or no argument to toggle.

### Bug Fixes

- **`switch-icons.sh`**: toggling icon mode no longer destroys the
  `SHOW_COST` setting. Was overwriting the entire config file; now
  edits only the `ICONS=` line.

---

## v1.2.0 — 2026-05-25

Better git state visibility, correct Nerd Font icons, and a color rendering fix that was silently breaking everything.

### Bug Fixes

- **Color rendering**: ANSI escape sequences were stored via bash string concatenation (`\033[32m` as literal text) and printed verbatim instead of rendering as color. All color variables now use `$'...'` quoting — actual escape bytes.
- **Push/pull indicators (`↑N` / `↓N`)**: only appeared when an upstream tracking branch was explicitly set via `git push -u`. Now falls back to `origin/<branch>` automatically.
- **Nerd Font sync icons**: `ICON_AHEAD` and `ICON_BEHIND` were pointing at U+E0A1/E0A2 (Powerline "LN" and lock glyphs). Now use `nf-md-arrow_up_bold` (U+F0737) and `nf-md-arrow_down_bold` (U+F072E), verified against the installed font's cmap.
- **Nerd Font dirty icon**: was U+F1C5 (file-image glyph). Fixed to U+F040 (`nf-fa-pencil`), then replaced by the new multi-state system below.

### New Features

- **Three-state git status**: the branch segment now shows up to three indicators that stack — `~` (yellow) for unstaged modifications, `+` (green) for staged changes, `?` (gray) for untracked files. `main ~+` means you have edits both staged and unstaged; `main +` means you're ready to commit.
- **Session cost estimate** (opt-in): set `SHOW_COST=true` in `.statusline.conf` to display estimated spend for the current session. Calculated from the session JSONL file using Anthropic's published per-token pricing. Defaults to `false` — intended for API plan users; Pro/Max/Teams subscription users don't need it.

---

## v1.1.0 — 2026-05-25

- Add `↑N` / `↓N` branch sync indicators showing commits ahead/behind the remote. Reads cached remote refs — no network call.

## v1.0.0 — 2026-05-24

Initial release. Model name, thinking effort, git repo + branch, 5h/7d rate limits with velocity indicators, and context window progress bar.
