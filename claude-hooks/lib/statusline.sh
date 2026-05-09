#!/usr/bin/env bash
# Reads Claude Code session JSON on stdin, prints a Tamagotchi line,
# then pipes the same payload to omc-hud so its rendering stays intact.
#
# CC statusline contract: read JSON on stdin → print to stdout. Output
# is rendered verbatim. Multi-line is allowed.

set -u

DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$DIR/theme.sh"

payload="$(cat -)"

# Pull context-remaining percent. Schemas vary across CC versions; try a
# couple of known fields. Anything non-integer is treated as "unknown".
pct=""
if command -v jq >/dev/null 2>&1 && [ -n "$payload" ]; then
  pct="$(printf '%s' "$payload" | jq -r '
    if .context_window.remaining_percentage != null then .context_window.remaining_percentage
    elif .context_window.used_percentage != null then (100 - .context_window.used_percentage)
    elif .session.context_remaining_percent then .session.context_remaining_percent
    elif .context_remaining_percent then .context_remaining_percent
    elif .tokens.remaining and .tokens.total then ((.tokens.remaining / .tokens.total) * 100 | floor)
    else empty end' 2>/dev/null)"
fi

# Strict integer guard — anything else (float, string, "null") falls through to idle path.
if ! [[ "$pct" =~ ^[0-9]+$ ]]; then
  pct=""
fi

if [ -n "$pct" ]; then
  [ "$pct" -gt 100 ] && pct=100
  filled=$(( pct / 10 ))
  empty=$(( 10 - filled ))

  bar=""
  i=0
  while [ "$i" -lt "$filled" ]; do bar="${bar}█"; i=$(( i + 1 )); done
  i=0
  while [ "$i" -lt "$empty" ];  do bar="${bar}░"; i=$(( i + 1 )); done

  if   [ "$pct" -ge 70 ]; then face="(•ᴗ•)";    col="$OSHI_FG_OK"
  elif [ "$pct" -ge 40 ]; then face="(•ω•)";    col="$OSHI_FG_WARN"
  else                          face="(｡•́︿•̀｡)"; col="$OSHI_FG_LOW"
  fi

  # Format string is fixed; vars are %s args (prevents format-string injection).
  printf '%sHP%s %s%s%s %s%s%s %s%s%%%s\n' \
    "$OSHI_FG_HP" "$OSHI_RESET" \
    "$col" "$bar" "$OSHI_RESET" \
    "$col" "$face" "$OSHI_RESET" \
    "$OSHI_FG_DIM" "$pct" "$OSHI_RESET"
else
  printf '%sokayu%s %s(•ω•) idle%s\n' \
    "$OSHI_FG_HP" "$OSHI_RESET" \
    "$OSHI_FG_DIM" "$OSHI_RESET"
fi

# Compose with upstream omc-hud. Same payload, untouched.
hud="$HOME/.claude/hud/omc-hud.mjs"
if [ -f "$hud" ]; then
  printf '%s' "$payload" | node "$hud" 2>/dev/null
fi
