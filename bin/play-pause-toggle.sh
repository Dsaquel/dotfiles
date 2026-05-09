#!/usr/bin/env bash
set -eu

status="$(playerctl --player=brave status 2>/dev/null || true)"

case "$status" in
    Playing) playerctl --player=brave pause 2>/dev/null ;;
    Paused)  playerctl --player=brave play  2>/dev/null ;;
    *)       playerctl play-pause 2>/dev/null || true   ;;
esac
