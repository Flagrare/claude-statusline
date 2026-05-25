Toggle session cost display in the statusline. Pass "on"/"true" to enable or "off"/"false" to disable. Toggles if no argument given. Intended for API plan users.

Run this command via Bash:

"$(dirname "$(jq -r '.statusLine.command' ~/.claude/settings.json)")"/switch-cost.sh $ARGUMENTS

Report the output to the user.
