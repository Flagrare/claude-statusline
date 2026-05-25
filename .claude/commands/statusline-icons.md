Switch statusline icon mode. Modes: "emoji" (default, works everywhere) or "nerd" (Nerd Font glyphs, requires terminal font set to a Nerd Font). Toggles if no argument given.

Run this command via Bash:

"$(dirname "$(jq -r '.statusLine.command' ~/.claude/settings.json)")"/switch-icons.sh $ARGUMENTS

Report the output to the user.
