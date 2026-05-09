#!/usr/bin/env bash
# Oshi-aware urgency dispatcher.
# Usage: notify.sh <urgency> [summary] [body]
#   urgency: task-done | permission-requested | idle-waiting

set -u

OSHI_THEME_ROOT="${OSHI_THEME_ROOT:-$HOME/.local/share/oshi-theme}"
OSHI="${OSHI:-$(cat "$HOME/.cache/theme-switch/oshi" 2>/dev/null || echo plain)}"
OSHI_DIR="${OSHI_DIR:-$OSHI_THEME_ROOT/$OSHI}"
[ -f "$OSHI_DIR/branding.env" ] && . "$OSHI_DIR/branding.env"

urgency="${1:-task-done}"
summary="${2:-${OSHI_DISPLAY_NAME:-Claude Code}}"
body="${3:-}"

# Debounce: collapse repeat fires of the same urgency within the window.
OSHI_DEBOUNCE_MS="${OSHI_DEBOUNCE_MS:-2500}"
_runtime_dir="${XDG_RUNTIME_DIR:-/tmp}/oshi-theme"
mkdir -p "$_runtime_dir" 2>/dev/null || _runtime_dir="/tmp"
_marker="$_runtime_dir/last-${urgency}.ms"
_now_ms=$(date +%s%3N)
if [ -f "$_marker" ]; then
  _last_ms=$(cat "$_marker" 2>/dev/null || echo 0)
  if [ "$((_now_ms - _last_ms))" -lt "$OSHI_DEBOUNCE_MS" ]; then
    exit 0
  fi
fi
printf '%s' "$_now_ms" > "$_marker"

# Focus check (Hyprland): suppress when the user is already looking at this
# Claude Code terminal. Set OSHI_FOCUS_CHECK=0 to disable.
if [ "${OSHI_FOCUS_CHECK:-1}" = "1" ] && command -v hyprctl >/dev/null 2>&1; then
  _focused_pid="$(hyprctl activewindow -j 2>/dev/null | jq -r '.pid // 0' 2>/dev/null || echo 0)"
  if [ "$_focused_pid" -gt 1 ] 2>/dev/null; then
    _pid=$$
    _depth=0
    while [ "$_pid" -gt 1 ] && [ "$_depth" -lt 12 ]; do
      if [ "$_pid" = "$_focused_pid" ]; then
        exit 0
      fi
      _pid="$(ps -o ppid= -p "$_pid" 2>/dev/null | tr -d ' ')"
      [ -z "$_pid" ] && break
      _depth=$((_depth + 1))
    done
  fi
fi

case "$urgency" in
  task-done)
    image="$OSHI_DIR/images/task-done.png"
    sound="$OSHI_DIR/sounds/task-done.ogg"
    nf_urgency="normal"
    [ -z "$body" ] && body="Turn complete"
    ;;
  permission-requested)
    image="$OSHI_DIR/images/permission-requested.png"
    sound="$OSHI_DIR/sounds/permission-requested.ogg"
    nf_urgency="critical"
    [ -z "$body" ] && body="Permission requested"
    ;;
  idle-waiting)
    image="$OSHI_DIR/images/idle-waiting.png"
    sound="$OSHI_DIR/sounds/idle-waiting.ogg"
    nf_urgency="low"
    [ -z "$body" ] && body="Waiting on you"
    ;;
  *)
    echo "notify.sh: unknown urgency '$urgency'" >&2
    exit 2
    ;;
esac

# Image is optional — notify-send still fires without one.
icon_arg=()
[ -f "$image" ] && icon_arg=(--icon="$image")

OSHI_TIMEOUT_MS="${OSHI_TIMEOUT_MS:-3000}"

notify-send \
  --app-name="${OSHI_DISPLAY_NAME:-Claude Code}" \
  --urgency="$nf_urgency" \
  --expire-time="$OSHI_TIMEOUT_MS" \
  "${icon_arg[@]}" \
  "$summary" "$body"

# Audio playback. Detached so the hook does not block the next turn.
# Plain mode is silent: when sound file is missing, this block is a no-op.
OSHI_VOLUME="${OSHI_VOLUME:-0.50}"
if [ -f "$sound" ]; then
  if command -v paplay >/dev/null 2>&1; then
    pa_vol=$(awk -v v="$OSHI_VOLUME" 'BEGIN { printf "%d", v * 65536 }')
    setsid -f paplay --volume="$pa_vol" "$sound" >/dev/null 2>&1
  elif command -v pw-play >/dev/null 2>&1; then
    setsid -f pw-play --volume="$OSHI_VOLUME" "$sound" >/dev/null 2>&1
  fi
fi
