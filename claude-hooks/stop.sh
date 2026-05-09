#!/usr/bin/env bash
# Stop hook: fired when Claude Code finishes a turn.

DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

exec "$DIR/notify.sh" task-done "" "Turn complete" </dev/null
