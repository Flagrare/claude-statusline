# Changelog

## v1.2.1 — 2026-05-25

### New Features

- **`/statusline-cost`**: new slash command to toggle session cost display without editing `.statusline.conf` by hand. Accepts `on`, `off`, or no argument to toggle. Mirrors the existing `/statusline-icons` command.

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
