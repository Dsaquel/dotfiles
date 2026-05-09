#!/usr/bin/env fish

set -l repo_dir (realpath (dirname (status filename)))
cd $repo_dir

if not type -q stow
    echo "stow not installed. Run: sudo pacman -S --needed stow"
    exit 1
end

set -l pkg_map \
    "bash:$HOME" \
    "bin:$HOME/.local/bin" \
    "btop:$HOME/.config/btop" \
    "claude:$HOME/.claude" \
    "claude-hooks:$HOME/.config/agent-hooks/claude-code" \
    "fish:$HOME/.config/fish" \
    "fuzzel:$HOME/.config/fuzzel" \
    "git:$HOME" \
    "htop:$HOME/.config/htop" \
    "hypr:$HOME/.config/hypr" \
    "kitty:$HOME/.config/kitty" \
    "lazygit:$HOME/.config/lazygit" \
    "nvim:$HOME/.config/nvim" \
    "oshi-theme:$HOME/.local/share/oshi-theme" \
    "profile:$HOME" \
    "swaync:$HOME/.config/swaync" \
    "tmux:$HOME/.config/tmux" \
    "waybar:$HOME/.config/waybar" \
    "wlogout:$HOME/.config/wlogout"

set -l mode stow
set -l requested
for arg in $argv
    switch $arg
        case -h --help
            echo "Usage: ./install.fish [-D|--delete] [PACKAGE ...]"
            echo "  no args        : (un)stow every package in the map"
            echo "  PACKAGE ...    : (un)stow only the listed packages"
            echo "  -D | --delete  : unstow instead of stow"
            exit 0
        case -D --delete
            set mode unstow
        case '*'
            set requested $requested $arg
    end
end

set -l action_label
switch $mode
    case stow;   set action_label stowing
    case unstow; set action_label unstowing
end

for entry in $pkg_map
    set -l parts (string split -m 1 ':' $entry)
    set -l pkg $parts[1]
    set -l target $parts[2]

    if test (count $requested) -gt 0; and not contains $pkg $requested
        continue
    end

    if not test -d $pkg
        echo "skip $pkg (not a directory)"
        continue
    end

    mkdir -p $target
    echo "$action_label $pkg → $target"
    switch $mode
        case stow;   stow -v --dir=$repo_dir --target=$target $pkg
        case unstow; stow -v -D --dir=$repo_dir --target=$target $pkg
    end
end

echo
echo done.
