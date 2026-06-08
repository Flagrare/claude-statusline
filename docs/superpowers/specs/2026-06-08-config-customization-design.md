# Config customization — design spec

**Date:** 2026-06-08
**Ships as:** v2.8.0
**Scope:** Two related, user-facing configuration improvements to claude-statusline:
1. A **customizable context-token warning threshold** (replaces the hardcoded 200k).
2. An **interactive checklist** (`configure.sh`) reachable two ways — an Advanced install path and a new `/statusline-config` command.

---

## Feature 1 — Customizable context-warning threshold

### Today
The over-200k badge fires on Claude Code's fixed `exceeds_200k_tokens` boolean. Label (`>200k`) and the 200k trigger are hardcoded.

### Design
Claude Code's status JSON exposes absolute context tokens (verified live):
`.context_window.total_input_tokens` (current context occupancy) and `.context_window.context_window_size`.

- **New config value:** `CONTEXT_WARNING_TOKENS`, default `200000`. So out-of-the-box behavior is unchanged.
- **Trigger:** with `SHOW_CONTEXT_WARNING=true`, render the badge when `total_input_tokens >= CONTEXT_WARNING_TOKENS`.
- **Label derives from the value** (no separate label config): humanize the threshold —
  - `>= 1_000_000` → `>X.YM` (strip trailing `.0`, e.g. `1000000 → >1M`, `1500000 → >1.5M`)
  - `>= 1000` → `>Nk` (e.g. `200000 → >200k`, `150000 → >150k`)
  - else → `>N`
- **Fallback:** if `total_input_tokens` is empty/absent (older Claude Code), fall back to the `exceeds_200k_tokens` boolean with a `>200k` label.
- **Command:** `/statusline-context-warning`
  - `on` / `off` → toggle `SHOW_CONTEXT_WARNING` (existing).
  - `<number>` → set `CONTEXT_WARNING_TOKENS`, accepting `150000` or `150k`/`1.5M` (suffix parsed to an integer).

### Touch points
- `statusline.sh` jq block: parse `total_input_tokens`.
- `statusline.sh` `ctx_warn_seg` block: threshold comparison + label derivation + fallback.
- `switch-context-warning.sh`: accept a numeric argument in addition to on/off.
- `install.sh` default conf: add `CONTEXT_WARNING_TOKENS=200000`.

### Edge cases
- `total_input_tokens` present but `CONTEXT_WARNING_TOKENS` unset → default `200000`.
- Non-integer / malformed `CONTEXT_WARNING_TOKENS` → treat as default `200000`.
- Numeric arg with bad suffix → switch script rejects with a usage message, conf unchanged.

---

## Feature 2 — Interactive checklist (`configure.sh`)

### Component
A standalone script `configure.sh` installed to `~/.claude/statusline/`. It is the **single** implementation of the feature-picker UX, used by both entry points below.

**Behavior:**
1. Read the current `.statusline.conf` (in `configure.sh`'s own dir).
2. Prompt for **icon mode** — a 4-way numbered choice (`emoji` / `nerd` / `unicode` / `ascii`), pre-selecting the current value (or `nerd` if a Nerd Font is detected and none set).
3. Present a **numbered checklist** of the 16 `SHOW_*` toggles, each pre-checked to its current conf value. The user types space-separated numbers to flip entries and presses Enter to accept.
4. Write the updated `.statusline.conf`. **Managed keys** = the 16 `SHOW_*` toggles + `ICONS`; these are rewritten from the checklist state. **All other keys** (e.g. `CONTEXT_WARNING_TOKENS`, plus any future settings) are preserved untouched.

**Toggles in the checklist (16):** git-diff-stats, pr, worktree, conflicts, sonnet-limit, output-style, session-id, claude-version, cwd, session-duration, token-speed, compaction, extra-usage, cost, fast-mode, context-warning. Default-on: worktree, conflicts, fast-mode, context-warning.

**Implementation constraints:**
- **macOS bash 3.2 compatible** — no associative arrays, no `${var,,}`. Use parallel indexed arrays (`keys[]`, `labels[]`, `state[]`) and `tr` for case folding.
- Input read via `read` (works both when run directly and under `bash <(curl …)`).
- Redraw the list each round until the user accepts; ignore non-numeric / out-of-range tokens silently.

### Entry point A — `/statusline-config`
New command `.claude/commands/statusline-config.md` runs `~/.claude/statusline/configure.sh` against the live config. Re-toggle anything, anytime. The per-feature `/statusline-*` commands remain for quick single flips; `configure.sh` is the "show everything" view.

### Entry point B — Advanced install
`install.sh` opens with a mode prompt (default Quick):
```
Setup mode:
  1) Quick    — recommended defaults (icons + cost only)
  2) Advanced — choose every feature
> [1]
```
- **Quick:** byte-for-byte the current flow (nerd-font y/N, cost y/N, default conf).
- **Advanced:** download files via the manifest (which now includes `configure.sh`), write the default conf, then `bash "$INSTALL_DIR/configure.sh"`. Same screen, same code as `/statusline-config`.

### Data flow
```
install.sh (Advanced)  ─┐
                        ├─→ configure.sh ──reads/writes──> ~/.claude/statusline/.statusline.conf
/statusline-config  ────┘
```

### Touch points / new files
- New: `configure.sh` → manifest `bin configure.sh`.
- New: `.claude/commands/statusline-config.md` → manifest `cmd …`.
- `install.sh`: mode prompt + Advanced branch that execs `configure.sh`.
- `README.md`: document `/statusline-config` and the Advanced install path; segment table note for the configurable threshold.

### Edge cases
- Missing `.statusline.conf` → `configure.sh` starts from built-in defaults and writes a fresh one.
- User accepts with no changes → conf rewritten identically (idempotent).
- Conf has unknown/extra keys → preserved (rewrite only the managed lines).
- No Nerd Font + user picks `nerd` → allowed (they may install one later); we don't block.

---

## Testing

- **Threshold:** feed `statusline.sh` JSON with `total_input_tokens` below/at/above the configured value; assert the badge appears only at/above, with the derived label. Unit-check the humanizer for `200000`, `150000`, `1000000`, `1500000`.
- **Fallback:** JSON without `total_input_tokens` but with `exceeds_200k_tokens=true` → `>200k` renders.
- **switch-context-warning.sh:** `on`/`off`/`150k`/garbage — assert conf writes / rejects correctly.
- **configure.sh:** run under `/bin/bash` (3.2) on macOS; drive it with scripted input; assert the resulting conf matches the toggled selection; verify unknown keys survive.
- **install Advanced:** `configure.sh` carries the real coverage (install just execs it); smoke-test the mode prompt branches.

## Non-goals (YAGNI)
- No threshold field inside `configure.sh` (the checklist is for toggles; the value lives in `/statusline-context-warning N`).
- No wizard on `update` (it preserves existing config, as today).
- No TUI library (whiptail/dialog) — pure bash for portability.
