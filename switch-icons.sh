#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="$SCRIPT_DIR/.statusline.conf"

current=$(grep '^ICONS=' "$CONF" 2>/dev/null | cut -d= -f2)
[ -z "$current" ] && current="emoji"

if [ -n "$1" ]; then
  case "$1" in
    emoji|nerd|unicode|ascii) target="$1" ;;
    *) echo "Unknown mode: $1 (valid: emoji, nerd, unicode, ascii)"; exit 1 ;;
  esac
else
  # No arg: cycle emoji → nerd → unicode → ascii → emoji
  case "$current" in
    emoji)   target="nerd"    ;;
    nerd)    target="unicode" ;;
    unicode) target="ascii"   ;;
    ascii)   target="emoji"   ;;
    *)       target="emoji"   ;;
  esac
fi

if grep -q '^ICONS=' "$CONF" 2>/dev/null; then
  # Portable in-place edit (matches the mktemp pattern in install/update/uninstall).
  # `sed -i ''` is BSD/macOS-only; on GNU sed (Linux/WSL) the '' is read as the
  # script and $CONF as a second input file, so the write silently fails.
  tmp=$(mktemp)
  sed "s/^ICONS=.*/ICONS=${target}/" "$CONF" > "$tmp"
  mv "$tmp" "$CONF"
else
  echo "ICONS=${target}" >> "$CONF"
fi

echo "Switched: $current → $target"

case "$target" in
  nerd)
    echo "  Requires terminal font set to a Nerd Font (JetBrainsMono Nerd Font, FiraCode Nerd Font, etc.)."
    ;;
  unicode)
    echo "  Geometric Unicode symbols (≫ ∼ ≡ ※ ◉ ├ ▴ ▾) with text-presentation."
    echo "  Recommended for Warp and other terminals that render emoji at wrong sizes."
    ;;
  ascii)
    echo "  Pure 7-bit ASCII (!! ~~ == [*] [D] |- ^ v) — works in any terminal,"
    echo "  including non-UTF8 environments. Maximum compatibility."
    ;;
  emoji)
    echo "  Default colorful icons. Works in most modern terminals."
    echo "  If your terminal renders emoji at wrong sizes (Warp default font),"
    echo "  try \`/statusline-icons unicode\` instead."
    ;;
esac
