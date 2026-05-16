# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal dotfiles managed by **GNU Stow**. Not a typical software project — there is no build/lint/test pipeline. Changes are applied to the live system by symlinking package directories into `$HOME` (or other targets) via `./install.fish`.

## Common commands

```fish
./install.fish                  # stow every package in the map
./install.fish hypr nvim        # stow only the listed packages
./install.fish -D               # unstow everything (--delete also works)
./install.fish -D fish          # unstow only fish

bin/theme-switch.sh toggle      # flip between latte/mocha
bin/theme-switch.sh auto        # pick by clock (≥6 and <19 → latte, else mocha)
bin/theme-switch.sh oshi okayu  # change oshi (branding overlay), re-render in current mode
```

The pre-flight check is `stow` itself (`pacman -S --needed stow`). There is no separate dependency-install step; downstream tools (hyprland, kitty, waybar, swaync, fuzzel, awww, jq, etc.) must be installed manually before the stowed configs become useful.

## Stow architecture — the package→target map

`install.fish` is the single source of truth for which top-level directories get stowed and where. The mapping (`pkg_map` in `install.fish:11-30`) deliberately does **not** point every package at `$HOME` — most go under `$HOME/.config/<name>`, a few go elsewhere:

| Package          | Target                                  |
|------------------|-----------------------------------------|
| `bash`, `git`, `profile` | `$HOME`                         |
| `bin`            | `$HOME/.local/bin`                      |
| `claude`         | `$HOME/.claude`                         |
| `claude-hooks`   | `$HOME/.config/agent-hooks/claude-code` |
| `oshi-theme`     | `$HOME/.local/share/oshi-theme`         |
| everything else  | `$HOME/.config/<package-name>`          |

**When adding a new package**, edit `pkg_map` — otherwise `install.fish` silently skips it. Each entry is `package:absolute-target-path`, colon-separated, parsed with `string split -m 1 ':'`.

`claude/` and `claude-hooks/` are intentionally separate trees: `claude/` populates `~/.claude/` (Claude Code's own config dir, including `settings.json` and TUI hooks like `caveman-activate.js`), while `claude-hooks/` populates a separate agent-hooks tree referenced from `claude/settings.json` (e.g. statusline command path). Don't merge them.

## Theme system — read before touching `bin/theme-switch.sh`

The theme switcher is a single bash script that atomically retargets a fleet of symlinks and rewrites a handful of mutable config files. It is the most fragile piece in the repo. Three invariants govern it:

1. **CRITICAL vs OPTIONAL steps.** The header comment block (`bin/theme-switch.sh:5-13`) declares this contract. CRITICAL steps must never `|| true` — they have to surface failure so the `trap rollback ERR` (`bin/theme-switch.sh:101`) fires. OPTIONAL steps (best-effort reload signals: waybar SIGUSR2, swaync-client, kitty SIGUSR1, xsettingsd, hyprctl env, gsettings) are allowed to swallow errors with a reason comment, because their failure is non-catastrophic (a tool may not be running yet, or may auto-pick up on next launch). When editing, preserve the comment on every `|| true`.
2. **Snapshot-restore rollback.** Symlinks can be re-pointed cheaply, but mutable files (GTK ini, Kvantum kvconfig, btop.conf, hyprlock.conf, waybar `style-active.css`) are snapshotted at the top of the script and rewritten by `rollback()` if anything blows up. If you add a new mutable file, add it to both the snapshot block (`bin/theme-switch.sh:45-50`) and `rollback()` (`bin/theme-switch.sh:58-100`).
3. **Hyprland log coherence check.** After `hyprctl reload`, the script diffs the Hyprland log against its line count from before the reload (`bin/theme-switch.sh:373-386`). A new `Config error` or `Couldn't find file` line triggers rollback. Don't bypass this check.

### Generated runtime artifacts (gitignored, NOT stowed)

The theme switcher generates the "active" variant of each themed config at runtime. These are listed in `.gitignore` and are not part of any stow package:

```
waybar/style-active.css        swaync/style.css        swaync/style-active.css
kitty/theme-active.conf        tmux/theme-active.conf  hypr/themes/active.conf
fish/conf.d/tide-active.fish   fuzzel/fuzzel.ini       lazygit/config.yml
```

What this means in practice:

- The `*-mocha.{conf,css,fish,yml,ini}` and `*-latte.{...}` sibling files **are** committed — they are the inputs.
- The `*-active.*` files **are not** committed — they are outputs of `theme-switch.sh`, regenerated on every switch.
- Editing the active file by hand will be wiped on the next switch. Edit the mode-specific sibling instead.
- After a fresh `./install.fish`, the active files don't exist yet; run `bin/theme-switch.sh auto` (or toggle) to materialize them.

### Oshi overlay layer

On top of the mocha/latte axis, the script applies an "oshi" branding overlay (currently `okayu` or `plain`, stored in `~/.cache/theme-switch/oshi`). Each themed tool that supports `@import`/`include`/`source` reads two files: the mode (`style-mocha.css`) and the oshi overlay (`overlay/okayu-mocha.css`). Tools without include support (fuzzel, lazygit) get accent hexes substituted via `sed` against per-oshi values in the switcher. New oshi → add a directory under `oshi-theme/` plus matching `overlay/<oshi>-{latte,mocha}.{conf,css}` files in each themed package.

State lives in `~/.cache/theme-switch/`: `current` holds `latte`|`mocha`, `oshi` holds the oshi name. The libraries under `claude-hooks/lib/` (`theme.sh`, `statusline.sh`) read these to colorize the statusline and notifications.

## Notes when editing

- `nvim/` is a fork of [craftzdog/dotfiles-public](https://github.com/craftzdog/dotfiles-public) — keep the LazyVim plugin-spec layout (`lua/config/`, `lua/plugins/`). The nvim flavour is read from `$XDG_RUNTIME_DIR/nvim-flavour`, written by `theme-switch.sh`, and applied by an autocmd in `lua/plugins/colorscheme.lua`.
- `fish/config.fish` auto-execs `start-hyprland` on TTY1 login (`fish/config.fish:42-46`). Don't break that branch — it's the boot path into the graphical session.
- `claude/settings.json` is the source-of-truth for Claude Code TUI behavior: hook wiring (SessionStart/UserPromptSubmit/Stop/Notification → scripts in `~/.claude/hooks/`), statusline command (→ `claude-hooks/lib/statusline.sh` via the agent-hooks symlink), and the `theme` field (rewritten by `theme-switch.sh:251-257` with `jq` to track the current mode).
- `.omc/` is per-repo OMC orchestration state — gitignored, recreated on demand, safe to wipe.
- `hypr/IDEAS.txt` is local scratch — also gitignored.
