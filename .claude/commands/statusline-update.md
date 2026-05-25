Pull the latest version of claude-statusline from GitHub and sync commands.

Run this command via Bash:

INSTALL_DIR="$(dirname "$(jq -r '.statusLine.command' ~/.claude/settings.json)")" && cd "$INSTALL_DIR" && git pull origin main && bash -c 'COMMANDS_SRC="$PWD/.claude/commands"; COMMANDS_DST="$HOME/.claude/commands"; mkdir -p "$COMMANDS_DST"; for f in "$COMMANDS_SRC"/statusline-*.md; do [ -f "$f" ] || continue; base="$(basename "$f")"; rm -f "$COMMANDS_DST/$base"; ln -s "$f" "$COMMANDS_DST/$base"; done'

Report the output to the user. If new commands were added, mention they should run /reload-plugins.
