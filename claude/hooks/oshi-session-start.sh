#!/usr/bin/env bash
# CC wrapper → shared agent-hooks logic. Same script reusable from OpenCode.
exec "$HOME/.config/agent-hooks/claude-code/session-start.sh" "$@"
