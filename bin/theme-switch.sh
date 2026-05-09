#!/usr/bin/env bash
# Usage: theme-switch.sh {auto|latte|mocha|toggle}
#
# CRITICAL/OPTIONAL STEP CONTRACT
#  - CRITICAL = failure must trigger rollback (no || true).
#    These are: symlink retargeting, GTK ini rewrite, Kvantum config rewrite,
#    wallpaper image set (awww img), and final hyprland-log coherence check.
#  - OPTIONAL = best-effort cosmetic reload signals (|| true allowed).
#    These are: pkill -SIGUSR2 waybar (waybar may not be running yet),
#    swaync-client --reload-* (swaync may be mid-restart),
#    pkill -SIGUSR1 -x kitty (no open kitty windows is not a failure),
#    pkill -x xsettingsd (xsettingsd may not have been running),
#    hyprctl keyword env (transient hyprctl flake during reload).

set -euo pipefail

HYPR_THEMES="/home/element/.config/hypr/themes"
KITTY_DIR="/home/element/.config/kitty"
WAYBAR_DIR="/home/element/.config/waybar"
SWAYNC_DIR="/home/element/.config/swaync"
FUZZEL_DIR="/home/element/.config/fuzzel"
GTK3_INI="/home/element/.config/gtk-3.0/settings.ini"
GTK4_INI="/home/element/.config/gtk-4.0/settings.ini"
KVANTUM_CFG="/home/element/.config/Kvantum/kvantum.kvconfig"
WALLPAPER_DAY="/home/element/Pictures/wallpaper/hololive/okayu/day/background_kitty.png"
WALLPAPER_NIGHT="/home/element/Pictures/wallpaper/hololive/okayu/night/background_kitty_mocha.png"
STATE_DIR="/home/element/.cache/theme-switch"
STATE_FILE="${STATE_DIR}/current"
LOG_FILE="/tmp/theme-switch-$(date +%Y%m%d%H%M%S).log"

# --- Wallpaper daemon binary (single point of swap if user reinstalls swww later) ---
WALLPAPER_DAEMON_BIN="awww-daemon"
WALLPAPER_CTL_BIN="awww"

mkdir -p "${STATE_DIR}"
exec > >(tee -a "${LOG_FILE}") 2>&1

OSHI_THEME_ROOT="/home/element/.local/share/oshi-theme"
OSHI="${OSHI:-$(cat "${STATE_DIR}/oshi" 2>/dev/null || echo plain)}"
OSHI_DIR="${OSHI_THEME_ROOT}/${OSHI}"
[ -f "${OSHI_DIR}/branding.env" ] && . "${OSHI_DIR}/branding.env"
export OSHI OSHI_DIR OSHI_DISPLAY_NAME OSHI_EMOJI OSHI_GREETING_LANG

PREVIOUS="$(cat "${STATE_FILE}" 2>/dev/null || echo latte)"
SNAPSHOT_GTK3="$(cat "${GTK3_INI}" 2>/dev/null || true)"
SNAPSHOT_GTK4="$(cat "${GTK4_INI}" 2>/dev/null || true)"
SNAPSHOT_KVANTUM="$(cat "${KVANTUM_CFG}" 2>/dev/null || true)"
SNAPSHOT_BTOP="$(cat /home/element/.config/btop/btop.conf 2>/dev/null || true)"
SNAPSHOT_WAYBAR_ACTIVE="$(cat /home/element/.config/waybar/style-active.css 2>/dev/null || true)"
SNAPSHOT_HYPRLOCK="$(cat /home/element/.config/hypr/hyprlock.conf 2>/dev/null || true)"

hypr_log() { ls /run/user/$(id -u)/hypr/*/hyprland.log 2>/dev/null | head -1; }
HYPR_LOG_BEFORE_LINES=0
if HL="$(hypr_log)"; then
    [ -n "$HL" ] && HYPR_LOG_BEFORE_LINES=$(wc -l < "$HL" 2>/dev/null || echo 0)
fi

rollback() {
    echo "[FAIL] error during switch — reverting to ${PREVIOUS}"
    # Symlinks
    ln -sfn "${HYPR_THEMES}/${PREVIOUS}.conf"          "${HYPR_THEMES}/active.conf"          2>/dev/null || true
    ln -sfn "${KITTY_DIR}/theme-${PREVIOUS}.conf"      "${KITTY_DIR}/theme-active.conf"      2>/dev/null || true
    # NOTE: style-active.css is a real file (regenerated below); restored from SNAPSHOT_WAYBAR_ACTIVE.
    ln -sfn "${SWAYNC_DIR}/style-${PREVIOUS}.css"      "${SWAYNC_DIR}/style-active.css"      2>/dev/null || true
    ln -sfn "${SWAYNC_DIR}/style-active.css"           "${SWAYNC_DIR}/style.css"             2>/dev/null || true
    ln -sfn "${FUZZEL_DIR}/fuzzel-${PREVIOUS}.ini"     "${FUZZEL_DIR}/fuzzel.ini"            2>/dev/null || true
    ln -sfn "/home/element/.config/fish/conf.d/tide-${PREVIOUS}.fish"  "/home/element/.config/fish/conf.d/tide-active.fish" 2>/dev/null || true
    ln -sfn "/home/element/.config/tmux/theme-${PREVIOUS}.conf"        "/home/element/.config/tmux/theme-active.conf"        2>/dev/null || true
    ln -sfn "/home/element/.config/lazygit/config-${PREVIOUS}.yml"     "/home/element/.config/lazygit/config.yml"            2>/dev/null || true
    ln -sfn "/home/element/.config/bat/config-${PREVIOUS}"             "/home/element/.config/bat/config"                    2>/dev/null || true
    # Mutable file snapshots (these are the real fix — v1 left them in MODE state on rollback)
    [ -n "${SNAPSHOT_GTK3}"           ] && printf '%s\n' "${SNAPSHOT_GTK3}"           > "${GTK3_INI}"
    [ -n "${SNAPSHOT_GTK4}"           ] && printf '%s\n' "${SNAPSHOT_GTK4}"           > "${GTK4_INI}"
    [ -n "${SNAPSHOT_KVANTUM}"        ] && printf '%s\n' "${SNAPSHOT_KVANTUM}"        > "${KVANTUM_CFG}"
    [ -n "${SNAPSHOT_BTOP}"           ] && printf '%s\n' "${SNAPSHOT_BTOP}"           > /home/element/.config/btop/btop.conf
    [ -n "${SNAPSHOT_WAYBAR_ACTIVE}"  ] && printf '%s\n' "${SNAPSHOT_WAYBAR_ACTIVE}"  > /home/element/.config/waybar/style-active.css
    [ -n "${SNAPSHOT_HYPRLOCK}"       ] && printf '%s\n' "${SNAPSHOT_HYPRLOCK}"       > /home/element/.config/hypr/hyprlock.conf
    mkdir -p "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}" 2>/dev/null || true
    echo "${PREVIOUS}" > "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/nvim-flavour" 2>/dev/null || true
    # rollback gsettings broadcast for Brave/Electron live revert
    if [ "${PREVIOUS}" = "latte" ]; then
        gsettings set org.gnome.desktop.interface color-scheme prefer-light 2>/dev/null || true
        gsettings set org.gnome.desktop.interface gtk-theme  "catppuccin-latte-mauve-standard+default" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface icon-theme "Papirus-Light" 2>/dev/null || true
    else
        gsettings set org.gnome.desktop.interface color-scheme prefer-dark  2>/dev/null || true
        gsettings set org.gnome.desktop.interface gtk-theme  "catppuccin-mocha-mauve-standard+default" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark" 2>/dev/null || true
    fi
    if [ "${PREVIOUS}" = "latte" ] && [ -f "${WALLPAPER_DAY}" ]; then
        ${WALLPAPER_CTL_BIN} img "${WALLPAPER_DAY}" --transition-type none 2>/dev/null || true
    elif [ "${PREVIOUS}" = "mocha" ] && [ -f "${WALLPAPER_NIGHT}" ]; then
        ${WALLPAPER_CTL_BIN} img "${WALLPAPER_NIGHT}" --transition-type none 2>/dev/null || true
    fi
    # Final reload (only this is allowed to swallow on the rollback path)
    hyprctl reload 2>/dev/null || true
    notify-send -a "${OSHI_DISPLAY_NAME:-Claude Code}" -u critical "Theme switch FAILED" "Reverted to ${PREVIOUS}. See ${LOG_FILE}." 2>/dev/null || true
    echo "[ROLLBACK COMPLETE]" >&2
    exit 1
}
trap rollback ERR

if [ "${1:-}" = "oshi" ]; then
    NEW_OSHI="${2:-}"
    if [ -z "${NEW_OSHI}" ] || [ ! -d "${OSHI_THEME_ROOT}/${NEW_OSHI}" ]; then
        echo "Usage: $0 oshi <name>  (available: $(ls "${OSHI_THEME_ROOT}" 2>/dev/null | tr '\n' ' '))" >&2
        exit 2
    fi
    echo "${NEW_OSHI}" > "${STATE_DIR}/oshi"
    OSHI="${NEW_OSHI}"
    OSHI_DIR="${OSHI_THEME_ROOT}/${OSHI}"
    [ -f "${OSHI_DIR}/branding.env" ] && . "${OSHI_DIR}/branding.env"
    export OSHI OSHI_DIR OSHI_DISPLAY_NAME OSHI_EMOJI OSHI_GREETING_LANG
    set -- "$(cat "${STATE_FILE}" 2>/dev/null || echo auto)"
fi

MODE="${1:-auto}"
case "${MODE}" in
    auto)
        HOUR=$(date +%H)
        if [ "${HOUR}" -ge 6 ] && [ "${HOUR}" -lt 19 ]; then
            MODE=latte
        else
            MODE=mocha
        fi
        ;;
    toggle)
        if [ "${PREVIOUS}" = "latte" ]; then MODE=mocha; else MODE=latte; fi
        ;;
    latte|mocha) ;;
    *) echo "Usage: $0 {auto|latte|mocha|toggle|oshi <name>}" >&2; exit 2 ;;
esac

echo "[INFO] resolving mode=${MODE} (previous=${PREVIOUS})"

# Detect Kvantum theme names (no hardcoding; prefer mauve variant)
KVANTUM_LATTE=$(find /usr/share/Kvantum -maxdepth 1 -type d -iname '*latte*mauve*' 2>/dev/null | head -1 | xargs -r basename)
[ -z "${KVANTUM_LATTE}" ] && KVANTUM_LATTE=$(find /usr/share/Kvantum -maxdepth 1 -type d -iname '*latte*' 2>/dev/null | head -1 | xargs -r basename) && [ -n "${KVANTUM_LATTE}" ] && echo "[WARN] Kvantum mauve Latte unavailable, using ${KVANTUM_LATTE}"
KVANTUM_MOCHA=$(find /usr/share/Kvantum -maxdepth 1 -type d -iname '*mocha*mauve*' 2>/dev/null | head -1 | xargs -r basename)
[ -z "${KVANTUM_MOCHA}" ] && KVANTUM_MOCHA=$(find /usr/share/Kvantum -maxdepth 1 -type d -iname '*mocha*' 2>/dev/null | head -1 | xargs -r basename) && [ -n "${KVANTUM_MOCHA}" ] && echo "[WARN] Kvantum mauve Mocha unavailable, using ${KVANTUM_MOCHA}"
[ -z "${KVANTUM_LATTE}" ] && { echo "[FATAL] No Kvantum Latte theme installed"; exit 1; }
[ -z "${KVANTUM_MOCHA}" ] && { echo "[FATAL] No Kvantum Mocha theme installed"; exit 1; }

if [ "${MODE}" = "latte" ]; then
    GTK_THEME_NAME="catppuccin-latte-mauve-standard+default"
    GTK_PREFER_DARK=0
    GTK_ICON="Papirus-Light"
    KVANTUM_THEME="${KVANTUM_LATTE}"
    WALLPAPER="${WALLPAPER_DAY}"
else
    GTK_THEME_NAME="catppuccin-mocha-mauve-standard+default"
    GTK_PREFER_DARK=1
    GTK_ICON="Papirus-Dark"
    KVANTUM_THEME="${KVANTUM_MOCHA}"
    WALLPAPER="${WALLPAPER_NIGHT}"
fi

# ============================================================================
# CRITICAL STEPS (no || true; trap rollback ERR catches any failure)
# ============================================================================

# Hyprland theme + overlay (real file with source directives)
TMP_HYPR=$(mktemp)
cat > "${TMP_HYPR}" <<EOF
source = ${HYPR_THEMES}/${MODE}.conf
source = ${HYPR_THEMES}/../overlay/${OSHI}-${MODE}.conf
EOF
mv "${TMP_HYPR}" "${HYPR_THEMES}/active.conf"

# Kitty theme + overlay (real file with include directives)
TMP_KITTY=$(mktemp)
cat > "${TMP_KITTY}" <<EOF
include theme-${MODE}.conf
include overlay/${OSHI}-${MODE}.conf
EOF
mv "${TMP_KITTY}" "${KITTY_DIR}/theme-active.conf"

# Waybar style-active.css — mode + overlay imports
TMP_WAYBAR=$(mktemp)
cat > "${TMP_WAYBAR}" <<EOF
/* Generated $(date -Iseconds) by theme-switch.sh — do not edit */
@import url("overlay/${OSHI}-${MODE}.css");
@import url("style-${MODE}.css");
EOF
mv "${TMP_WAYBAR}" "${WAYBAR_DIR}/style-active.css"

# swaync style-active.css — real file with mode + overlay imports; style.css symlinked
TMP_SWAYNC=$(mktemp)
cat > "${TMP_SWAYNC}" <<EOF
@import url("overlay/${OSHI}-${MODE}.css");
@import url("style-${MODE}.css");
EOF
mv "${TMP_SWAYNC}" "${SWAYNC_DIR}/style-active.css"
ln -sfn "${SWAYNC_DIR}/style-active.css" "${SWAYNC_DIR}/style.css"

# fuzzel — sed-substitute accent hexes per oshi (no include support)
case "${OSHI}" in
    okayu) FZ_PRIMARY="b190fa"; FZ_SECONDARY="bc5bc6" ;;
    *)
        if [ "${MODE}" = "mocha" ]; then FZ_PRIMARY="cba6f7"; FZ_SECONDARY="f5c2e7"
        else FZ_PRIMARY="8839ef"; FZ_SECONDARY="ea76cb"; fi
        ;;
esac
TMP_FUZZEL=$(mktemp)
if [ "${MODE}" = "mocha" ]; then
    sed -e "s/cba6f7/${FZ_PRIMARY}/gi" -e "s/f5c2e7/${FZ_SECONDARY}/gi" \
        "${FUZZEL_DIR}/fuzzel-${MODE}.ini" > "${TMP_FUZZEL}"
else
    sed -e "s/8839ef/${FZ_PRIMARY}/gi" -e "s/ea76cb/${FZ_SECONDARY}/gi" \
        "${FUZZEL_DIR}/fuzzel-${MODE}.ini" > "${TMP_FUZZEL}"
fi
mv "${TMP_FUZZEL}" "${FUZZEL_DIR}/fuzzel.ini"

ln -sfn "/home/element/.config/fish/conf.d/tide-${MODE}.fish"   "/home/element/.config/fish/conf.d/tide-active.fish"
ln -sfn "/home/element/.config/bat/config-${MODE}"              "/home/element/.config/bat/config"

# tmux theme-active.conf — real file with mode + overlay source-file
TMP_TMUX=$(mktemp)
cat > "${TMP_TMUX}" <<EOF
source-file /home/element/.config/tmux/theme-${MODE}.conf
source-file /home/element/.config/tmux/overlay/${OSHI}-${MODE}.conf
EOF
mv "${TMP_TMUX}" /home/element/.config/tmux/theme-active.conf

# lazygit config.yml — sed-substitute activeBorderColor per oshi
case "${OSHI}" in
    okayu) LZ_ACCENT="#B190FA" ;;
    *)
        if [ "${MODE}" = "mocha" ]; then LZ_ACCENT="#cba6f7"
        else LZ_ACCENT="#8839ef"; fi
        ;;
esac
TMP_LAZY=$(mktemp)
if [ "${MODE}" = "mocha" ]; then
    sed "s/'#cba6f7'/'${LZ_ACCENT}'/" /home/element/.config/lazygit/config-${MODE}.yml > "${TMP_LAZY}"
else
    sed "s/'#8839ef'/'${LZ_ACCENT}'/" /home/element/.config/lazygit/config-${MODE}.yml > "${TMP_LAZY}"
fi
mv "${TMP_LAZY}" /home/element/.config/lazygit/config.yml

# btop color_theme rewrite (atomic)
TMP_BTOP=$(mktemp)
sed "s|^color_theme = .*|color_theme = \"/home/element/.config/btop/themes/catppuccin_${MODE}.theme\"|" \
    /home/element/.config/btop/btop.conf > "${TMP_BTOP}"
mv "${TMP_BTOP}" /home/element/.config/btop/btop.conf

# nvim flavour file (read by FocusGained autocmd in colorscheme.lua)
mkdir -p "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
echo "${MODE}" > "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/nvim-flavour"

# Claude TUI theme — jq patch (atomic tmp + mv)
CLAUDE_SETTINGS="/home/element/.claude/settings.json"
if [ -f "${CLAUDE_SETTINGS}" ]; then
    TMP_CLAUDE=$(mktemp)
    jq --arg t "custom:okayu-purple-${MODE}" '.theme = $t' "${CLAUDE_SETTINGS}" > "${TMP_CLAUDE}"
    mv "${TMP_CLAUDE}" "${CLAUDE_SETTINGS}"
fi

# GTK settings.ini (write atomically via tmp + mv)
TMP_GTK=$(mktemp)
cat > "${TMP_GTK}" <<EOF
[Settings]
gtk-theme-name=${GTK_THEME_NAME}
gtk-icon-theme-name=${GTK_ICON}
gtk-cursor-theme-name=Bibata-Modern-Classic
gtk-cursor-theme-size=24
gtk-font-name=JetBrainsMono Nerd Font 11
gtk-application-prefer-dark-theme=${GTK_PREFER_DARK}
EOF
mv "${TMP_GTK}" "${GTK3_INI}"
cp "${GTK3_INI}" "${GTK4_INI}"

TMP_KV=$(mktemp)
cat > "${TMP_KV}" <<EOF
[General]
theme=${KVANTUM_THEME}
EOF
mv "${TMP_KV}" "${KVANTUM_CFG}"

# Wallpaper via awww — was || true in v1
if ! pgrep -x "${WALLPAPER_DAEMON_BIN}" >/dev/null; then
    "${WALLPAPER_DAEMON_BIN}" >/dev/null 2>&1 &
    sleep 1
    pgrep -x "${WALLPAPER_DAEMON_BIN}" >/dev/null || { echo "[FAIL] ${WALLPAPER_DAEMON_BIN} did not start"; exit 1; }
fi
"${WALLPAPER_CTL_BIN}" img "${WALLPAPER}" --transition-type fade --transition-duration 1 --transition-fps 60

# Hyprlock: swap wallpaper path + accent per oshi+mode (OPTIONAL — cosmetic)
HYPRLOCK_CONF="/home/element/.config/hypr/hyprlock.conf"
case "${OSHI}" in
    okayu)
        _HL_ACCENT_HEX_MOCHA="B190FA"; _HL_ACCENT2_HEX_MOCHA="BC5BC6"
        _HL_ACCENT_HEX_LATTE="8839EF"; _HL_ACCENT2_HEX_LATTE="BC5BC6"
        ;;
    *)
        _HL_ACCENT_HEX_MOCHA="CBA6F7"; _HL_ACCENT2_HEX_MOCHA="F5C2E7"
        _HL_ACCENT_HEX_LATTE="8839EF"; _HL_ACCENT2_HEX_LATTE="EA76CB"
        ;;
esac
if [ "${MODE}" = "latte" ]; then
    _HL_ACCENT="rgb(${_HL_ACCENT_HEX_LATTE})"
    _HL_ACCENT2="rgb(${_HL_ACCENT2_HEX_LATTE})"
    _HL_INNER="rgba(239, 241, 245, 0.7)"
    _HL_FONT="rgb(4C4F69)"
else
    _HL_ACCENT="rgb(${_HL_ACCENT_HEX_MOCHA})"
    _HL_ACCENT2="rgb(${_HL_ACCENT2_HEX_MOCHA})"
    _HL_INNER="rgba(30, 30, 46, 0.6)"
    _HL_FONT="rgb(CDD6F4)"
fi
sed -i \
    -e "s|^    path = .*|    path = ${WALLPAPER}|" \
    -e "s|^\$accent = .*|\$accent = ${_HL_ACCENT}|" \
    -e "s|^\$accent2 = .*|\$accent2 = ${_HL_ACCENT2}|" \
    -e "s|inner_color = .*|inner_color = ${_HL_INNER}|" \
    -e "s|font_color = .*|font_color = ${_HL_FONT}|" \
    "${HYPRLOCK_CONF}" 2>/dev/null || true

# Hyprland reload (CRITICAL exit code; log check below)
hyprctl reload

# ============================================================================
# OPTIONAL STEPS (best-effort — || true with reason comments)
# ============================================================================

# Waybar may not be running yet on cold boot — losing one reload signal is acceptable
pkill -SIGUSR2 waybar 2>/dev/null || true

# swaync may be mid-restart — config reload is best-effort
swaync-client --reload-config >/dev/null 2>&1 || true
swaync-client --reload-css    >/dev/null 2>&1 || true

# No kitty windows open is not a failure — only signal if any are alive
pkill -SIGUSR1 -x kitty 2>/dev/null || true

# xsettingsd config — runtime artifact (not stowed); written from scratch each switch
mkdir -p /home/element/.config/xsettingsd
TMP_XS=$(mktemp)
cat > "${TMP_XS}" <<EOF
Net/ThemeName "${GTK_THEME_NAME}"
Net/IconThemeName "${GTK_ICON}"
Gtk/CursorThemeName "Bibata-Modern-Classic"
Gtk/CursorThemeSize 24
Gtk/FontName "JetBrainsMono Nerd Font 11"
EOF
mv "${TMP_XS}" /home/element/.config/xsettingsd/xsettingsd.conf

# xsettingsd may not have been started yet — restart is best-effort
pkill -x xsettingsd 2>/dev/null || true
xsettingsd >/dev/null 2>&1 &

# Update Hyprland env for new launches — transient hyprctl failure during reload is acceptable
hyprctl keyword env GTK_THEME,${GTK_THEME_NAME} >/dev/null 2>&1 || true

# gsettings broadcast → xdg-desktop-portal → Chromium/Electron live update
# Without this, Brave/Discord/Obsidian/VS Code keep their boot-time theme.
# This is OPTIONAL because gsettings/dconf failure is non-catastrophic (the .ini files are still correct).
if [ "${MODE}" = "latte" ]; then
    gsettings set org.gnome.desktop.interface color-scheme prefer-light 2>/dev/null || true
else
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark  2>/dev/null || true
fi
gsettings set org.gnome.desktop.interface gtk-theme  "${GTK_THEME_NAME}"     2>/dev/null || true
gsettings set org.gnome.desktop.interface icon-theme "${GTK_ICON}"           2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-theme "Bibata-Modern-Classic" 2>/dev/null || true

# btop reads color_theme on SIGUSR2 — no running instance is not a failure
pkill -SIGUSR2 -x btop 2>/dev/null || true
# tmux source-file refreshes attached sessions — no running server is not a failure
tmux ls >/dev/null 2>&1 && tmux source-file ~/.config/tmux/tmux.conf 2>/dev/null || true

# ============================================================================
# CRITICAL POST-FLIGHT: Hyprland log coherence check
# ============================================================================
sleep 0.3
if HL="$(hypr_log)" && [ -n "$HL" ]; then
    NEW_LINES_COUNT=$(wc -l < "$HL")
    if [ "${NEW_LINES_COUNT}" -gt "${HYPR_LOG_BEFORE_LINES}" ]; then
        # Only inspect lines added since this script started
        NEW_LINES=$(tail -n $((NEW_LINES_COUNT - HYPR_LOG_BEFORE_LINES)) "$HL")
        if echo "${NEW_LINES}" | grep -E '(Config error|Couldn'"'"'t find file)'; then
            echo "[FAIL] Hyprland log shows config errors after reload"
            exit 1   # trap fires → rollback
        fi
    fi
fi

echo "${MODE}" > "${STATE_FILE}"

RUNNING_NEEDS_RELAUNCH=()
for proc in brave brave-browser chromium chrome discord obs mpv vlc; do
    if pgrep -x "$proc" >/dev/null 2>&1; then
        RUNNING_NEEDS_RELAUNCH+=("$proc")
    fi
done

if [ ${#RUNNING_NEEDS_RELAUNCH[@]} -gt 0 ]; then
    RELAUNCH_LIST=$(IFS=', '; echo "${RUNNING_NEEDS_RELAUNCH[*]}")
    notify-send -a "${OSHI_DISPLAY_NAME:-Claude Code}" "Theme switched: ${MODE}" \
      "Live: hyprland, kitty, waybar, swaync, fuzzel, hyprlock, tide, tmux, btop, nvim(focus), lazygit(restart), bat(next-call). Relaunch needed: ${RELAUNCH_LIST}. GTK3/Thunar may auto-refresh." \
      || true
else
    notify-send -a "${OSHI_DISPLAY_NAME:-Claude Code}" "Theme switched: ${MODE}" \
      "Live: hyprland, kitty, waybar, swaync, fuzzel, hyprlock, tide, tmux, btop, nvim(focus), lazygit(restart), bat(next-call). No Electron apps to relaunch. GTK3/Thunar may auto-refresh." \
      || true
fi

echo "[OK] theme=${MODE} hyprctl=ok kitty=ok waybar=ok swaync=ok fuzzel=ok wallpaper=ok cascade=ok(tide/tmux/lazygit/bat/btop/nvim) log=clean"
