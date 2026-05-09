# Oshi-aware fish greeting + branding env loader.
# Plain mode = silent shell start (Q6). Okayu mode keeps JP encouragement.
# config.fish already does `set -U fish_greeting ""`; this function definition supersedes it.

function _oshi_load_env
    set -gx OSHI (cat ~/.cache/theme-switch/oshi 2>/dev/null; or echo plain)
    set -gx OSHI_DIR "$HOME/.local/share/oshi-theme/$OSHI"
    set -l branding "$OSHI_DIR/branding.env"
    test -f "$branding"; or return
    while read -l line
        string match -q '#*' $line; and continue
        test -z "$line"; and continue
        set -l kv (string split -m 1 '=' $line)
        set -gx $kv[1] (string trim --chars '"' $kv[2])
    end < "$branding"
end

_oshi_load_env

function fish_greeting
    test "$OSHI" = "plain"; and return

    if test "$OSHI" = "okayu"
        set -l messages \
            "おかゆ〜ん!🍙 今日もがんばろうね" \
            "おにぎりみたいに、ぎゅっとがんばれ!🍙" \
            "ふぁ〜...おはよう。コーヒー飲む?☕" \
            "おかえり〜!ねこまた一緒にコーディングしよ?🐱" \
            "Stay comfy. Stay productive. 💜" \
            "おかゆうううう🍙✨"
        set -l idx (random 1 (count $messages))
        set_color B190FA
        echo $messages[$idx]
        set_color normal
    end
end
