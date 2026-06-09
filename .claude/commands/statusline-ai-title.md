Toggle the AI session title display in the statusline. Pass "on"/"true" to enable or "off"/"false" to disable. Toggles if no argument given.

Renders the auto-generated humanized session name (e.g. `📝 Statusline not showing current folder`) on row 2. The title is what Claude Code derives from the conversation and surfaces in `/sessions` and the resume picker — useful for keeping multiple terminal tabs straight.

**How it works**
- Reads the most recent `{"type":"ai-title","aiTitle":...}` record from the active session JSONL under `~/.claude/projects/<encoded-cwd>/`. Truncates to `AI_TITLE_MAX_CHARS` (default 40). Falls back silently when no title has been assigned yet.

**Disable anytime** with `/statusline-ai-title off`.

Run this command via Bash:

~/.claude/statusline/switch-ai-title.sh $ARGUMENTS

Report the output to the user.
