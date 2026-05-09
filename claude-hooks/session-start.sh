#!/usr/bin/env bash
# Oshi-aware SessionStart banner. Banner block gated for plain mode.

DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$DIR/lib/theme.sh"

cwd="${PWD}"
branch=""
if command -v git >/dev/null 2>&1; then
  branch="$(git -C "$cwd" branch --show-current 2>/dev/null || true)"
fi

todos=""
notepad="$cwd/.omc/notepad.md"
if [ -f "$notepad" ]; then
  todos="$(grep -E '^- \[ \]' "$notepad" 2>/dev/null | head -3 || true)"
fi

# Banner: skip in plain mode.
if [ "${OSHI:-plain}" != "plain" ]; then
  printf '\n'
  printf '%s   ____  _                       %s\n' "$OSHI_BANNER_LINE_1" "$OSHI_RESET"
  printf '%s  / __ \\| | ____ _ _   _ _   _   %s\n' "$OSHI_BANNER_LINE_2" "$OSHI_RESET"
  printf '%s | |  | | |/ /  ` | | | | | | |  %s\n' "$OSHI_BANNER_LINE_2" "$OSHI_RESET"
  printf '%s | |__| |   < (_| | |_| | |_| |  %s\n' "$OSHI_BANNER_LINE_3" "$OSHI_RESET"
  printf '%s  \\____/|_|\\_\\__,_|\\__, |\\__,_|  %s\n' "$OSHI_BANNER_LINE_3" "$OSHI_RESET"
  printf '%s                   |___/         %s\n' "$OSHI_BANNER_LINE_3" "$OSHI_RESET"
  printf '\n'
fi

if [ -n "$branch" ]; then
  printf '  %sbranch %s%s%s\n' "$OSHI_FG_DIM" "$OSHI_FG_ACCENT" "$branch" "$OSHI_RESET"
fi

if [ -n "$todos" ]; then
  printf '  %sopen todos%s\n' "$OSHI_FG_DIM" "$OSHI_RESET"
  printf '%s\n' "$todos" | sed 's/^/    /'
fi

printf '\n'
