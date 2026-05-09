#!/usr/bin/env bash
# Toggle kitty background opacity between opaque (0.92) and transparent (0.55).
# Usage: kitty-opacity-toggle.sh {opaque|transparent|toggle}
#
# Live updates all running kitty instances via per-pid /tmp/kitty-* sockets,
# and persists the new value into kitty.conf so future windows start at it.
set -euo pipefail

KITTY_CONF="/home/element/.config/kitty/kitty.conf"
STATE_DIR="/home/element/.cache/theme-switch"
OPACITY_STATE="${STATE_DIR}/kitty-opacity"

OPAQUE_VAL="0.92"
TRANSPARENT_VAL="0.55"

mkdir -p "${STATE_DIR}"
PREVIOUS=$(cat "${OPACITY_STATE}" 2>/dev/null || echo opaque)

MODE="${1:-toggle}"
case "${MODE}" in
    toggle)
        if [ "${PREVIOUS}" = "opaque" ]; then
            MODE=transparent
        else
            MODE=opaque
        fi
        ;;
    opaque|transparent) ;;
    *)
        echo "Usage: $0 {opaque|transparent|toggle}" >&2
        exit 2
        ;;
esac

case "${MODE}" in
    opaque)      VAL="${OPAQUE_VAL}"      ;;
    transparent) VAL="${TRANSPARENT_VAL}" ;;
esac

# Persist value into kitty.conf for future windows (atomic)
TMP_CONF=$(mktemp)
sed "s|^background_opacity .*|background_opacity ${VAL}|" "${KITTY_CONF}" > "${TMP_CONF}"
mv "${TMP_CONF}" "${KITTY_CONF}"

# Live-update all running kitty instances. load-config first so the running
# kitty has dynamic_background_opacity enabled (required by set-background-opacity).
APPLIED=0
for sock in /tmp/kitty-*; do
    [ -S "${sock}" ] || continue
    kitty @ --to "unix:${sock}" load-config 2>/dev/null || true
    if kitty @ --to "unix:${sock}" set-background-opacity --all "${VAL}" 2>/dev/null; then
        APPLIED=$((APPLIED + 1))
    fi
done

echo "${MODE}" > "${OPACITY_STATE}"
echo "[INFO] kitty opacity=${MODE} value=${VAL} live-applied to ${APPLIED} instance(s)"
