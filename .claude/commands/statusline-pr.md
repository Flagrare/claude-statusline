Toggle the PR link display in the statusline. Pass "on"/"true" to enable or "off"/"false" to disable. Toggles if no argument given.

Adds a `#1234` segment, OSC8-hyperlinked to the PR's URL, when the current branch has an associated GitHub PR. Color-coded by state: green (open), gray (draft), cyan (merged), red (closed).

**How it works**
- Calls `gh pr view --json url,state,number` in the background and writes the result to `~/.claude/.statusline-state/pr-<repo>-<branch>.json`. Cache TTL is 60s.
- The statusline renders only from the cache, so it never blocks on the network. First render after enabling shows nothing — the second render picks up the freshly-cached value.

**Requirements**
- The [GitHub CLI](https://cli.github.com/) (`gh`). When not installed, the segment stays hidden silently.

**Disable anytime** with `/statusline-pr off`.

Run this command via Bash:

~/.claude/statusline/switch-pr.sh $ARGUMENTS

Report the output to the user.
