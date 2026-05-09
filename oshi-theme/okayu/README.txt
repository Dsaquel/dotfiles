==============================================================================
OKAYU THEME PACK
==============================================================================

Layout
------
images/   PNG 128x128, alpha. One per urgency class (task-done,
          permission-requested, idle-waiting). _master.png is the
          full-resolution source with white background already stripped.
          _mascot64.png is a 64-px variant for terminal mascot use.

sounds/   OGG Opus, <1s, normalized to -16 LUFS. One per urgency class.

themes/   ANSI color manifests (mocha.env, latte.env). Sourced by
          ~/.config/agent-hooks/claude-code/lib/theme.sh.

Swapping in real Okayu artwork
------------------------------
1. Drop your real Okayu PNG (128x128, transparent bg) at:
     images/task-done.png
     images/permission-requested.png
     images/idle-waiting.png

2. If you only have one source image, regenerate the 3 variants with:

     SRC=~/path/to/your-okayu.png
     magick "$SRC" -resize 128x128 _master.png
     magick _master.png -modulate 105,120,100 task-done.png
     magick _master.png -modulate 100,140,85  permission-requested.png
     magick _master.png -modulate 85,90,140 -blur 0x0.6 idle-waiting.png

3. White-background source? Strip first:
     magick input.png -fuzz 12% -transparent white -resize 128x128 _master.png

Sounds: same idea — overwrite the .ogg files in sounds/. Keep them under 1s
and normalized to -16 LUFS (use ffmpeg -af loudnorm=I=-16:TP=-1.5:LRA=11).

Active theme
------------
Set $OKAYU_THEME to "mocha" (default) or "latte". The theme.sh helper
respects this and sources the matching .env file at runtime.
