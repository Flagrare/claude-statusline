Switch statusline icon mode between `emoji` (default), `nerd` (Nerd Font glyphs), `unicode` (geometric Unicode — Warp-safe), and `ascii` (pure 7-bit). With no argument, cycles `emoji → nerd → unicode → ascii → emoji`. Pass a mode name to set it directly.

Mode details:

- `emoji` — colorful default (🔥 🍃 ⚡️ 🧠 📂 🌿). Works in most modern terminals; some (Warp's default font) render emoji at width 1 so they look tiny — use `unicode` instead if you see that.
- `nerd` — Nerd Font glyphs. Requires terminal font set to a Nerd Font (JetBrainsMono Nerd Font, FiraCode Nerd Font, etc.) or the glyphs will render as tofu.
- `unicode` — geometric Unicode symbols (`≫ ∼ ≡ ※ ◉ ├ ▴ ▾`). All text-presentation, no emoji VS16, so they render at proper monospace width even in terminals that mis-size emoji. **Recommended for Warp.**
- `ascii` — pure 7-bit ASCII (`!! ~~ == [*] [D] |- ^ v`). Maximum compatibility — works in any terminal, including non-UTF8 environments. Color still does the visual work for rate limits.

Run this command via Bash:

~/.claude/statusline/switch-icons.sh $ARGUMENTS

Report the output to the user.
