#!/usr/bin/env bash
# Source this file to populate OSHI_FG_* color variables for the active mode.
# Resolves OSHI from $OSHI > ~/.cache/theme-switch/oshi > "plain".
# Resolves mode from $OSHI_MODE > $OKAYU_THEME (legacy) > ~/.cache/theme-switch/current > "mocha".

OSHI_THEME_ROOT="${OSHI_THEME_ROOT:-$HOME/.local/share/oshi-theme}"
_state_dir="$HOME/.cache/theme-switch"
_oshi="${OSHI:-$(cat "$_state_dir/oshi" 2>/dev/null || echo plain)}"
_mode="${OSHI_MODE:-${OKAYU_THEME:-$(cat "$_state_dir/current" 2>/dev/null || echo mocha)}}"
case "$_mode" in
  mocha|latte) ;;
  *) _mode="mocha" ;;
esac

OSHI_DIR="$OSHI_THEME_ROOT/$_oshi"
_palette="$OSHI_DIR/palette.env"

if [ -f "$_palette" ]; then
  # shellcheck source=/dev/null
  . "$_palette"
fi

# Map mode-suffixed vars to mode-agnostic names consumed by callers
case "$_mode" in
  mocha)
    OSHI_FG_PRIMARY="${OSHI_FG_PRIMARY_MOCHA:-}"
    OSHI_FG_DIM="${OSHI_FG_DIM_MOCHA:-}"
    OSHI_FG_OK="${OSHI_FG_OK_MOCHA:-}"
    OSHI_FG_WARN="${OSHI_FG_WARN_MOCHA:-}"
    OSHI_FG_LOW="${OSHI_FG_LOW_MOCHA:-}"
    OSHI_FG_ACCENT="${OSHI_FG_ACCENT_MOCHA:-}"
    OSHI_FG_HP="${OSHI_FG_HP_MOCHA:-}"
    OSHI_BANNER_LINE_1="${OSHI_BANNER_LINE_1_MOCHA:-}"
    OSHI_BANNER_LINE_2="${OSHI_BANNER_LINE_2_MOCHA:-}"
    OSHI_BANNER_LINE_3="${OSHI_BANNER_LINE_3_MOCHA:-}"
    ;;
  latte)
    OSHI_FG_PRIMARY="${OSHI_FG_PRIMARY_LATTE:-}"
    OSHI_FG_DIM="${OSHI_FG_DIM_LATTE:-}"
    OSHI_FG_OK="${OSHI_FG_OK_LATTE:-}"
    OSHI_FG_WARN="${OSHI_FG_WARN_LATTE:-}"
    OSHI_FG_LOW="${OSHI_FG_LOW_LATTE:-}"
    OSHI_FG_ACCENT="${OSHI_FG_ACCENT_LATTE:-}"
    OSHI_FG_HP="${OSHI_FG_HP_LATTE:-}"
    OSHI_BANNER_LINE_1="${OSHI_BANNER_LINE_1_LATTE:-}"
    OSHI_BANNER_LINE_2="${OSHI_BANNER_LINE_2_LATTE:-}"
    OSHI_BANNER_LINE_3="${OSHI_BANNER_LINE_3_LATTE:-}"
    ;;
esac

OSHI_RESET="${OSHI_RESET:-$'\033[0m'}"

[ -f "$OSHI_DIR/branding.env" ] && . "$OSHI_DIR/branding.env"

unset _state_dir _oshi _mode _palette
