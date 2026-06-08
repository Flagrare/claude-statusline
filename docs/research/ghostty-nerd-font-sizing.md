# Ghostty Nerd Font icon sizing & fallback

**Date:** 2026-06-08
**Question:** Why do nerd-mode statusline icons look small for one Ghostty user but fine for another, and can the statusline do anything about it?

## Sources

- [Ghostty — Option Reference (Configuration)](https://ghostty.org/docs/config/reference) — `font-family` semantics, fallback list behavior.
- [Ghostty — 1.2.0 Release Notes](https://ghostty.org/docs/install/release-notes/1-2-0) — auto-resize of Nerd Font symbols to cell size; standalone symbols-only built-in font.
- [Ghostty Discussion #3501 — Small font icons](https://github.com/ghostty-org/ghostty/discussions/3501)
- [Ghostty Discussion #7905 — NerdFont font variations](https://github.com/ghostty-org/ghostty/discussions/7905)
- [Ghostty Discussion #9872 — font-family falls back to default for every glyph](https://github.com/ghostty-org/ghostty/discussions/9872)

## Findings

- Ghostty embeds **JetBrains Mono** as its default and ships a **standalone symbols-only Nerd Font** as automatic fallback: *"Ghostty has a built-in font that provides this icon, so it will always be able to display it, no matter what your primary font is."* With `font-family` unset, nerd glyphs always render — no font install required.
- **As of Ghostty 1.2.0**, Ghostty *auto-resizes* Nerd Font symbols to the cell, the same way the official Nerd Fonts patcher does, whether the glyph comes from the built-in symbols or an explicit patched font: *"there is now no reason to use patched fonts in Ghostty."*
- Therefore the **icon source does not change icon size** on Ghostty ≥ 1.2.0. "Small" nerd icons are simply cell-sized monochrome glyphs — the nature of nerd mode — not a font defect.

## Live verification

Reproduced on **Ghostty 1.3.1** (the maintainer's machine, `font-family` unset): temporarily setting `font-family = "Hack Nerd Font Mono"` and reloading changed icon size **not at all** — confirming the built-in symbols and an explicit patched font resolve to the same cell-fitted size.

## How this was used

Corrected the README "Icons look small, washed out, or wrong" troubleshooting (under `## Icon modes`). An earlier draft wrongly claimed a `…Nerd Font Mono` family shrinks icons; the research + live test showed that's false on modern Ghostty. The fix for someone wanting bigger icons is `/statusline-icons emoji` (or `adjust-icon-height` to nudge nerd glyphs), not a font swap.
