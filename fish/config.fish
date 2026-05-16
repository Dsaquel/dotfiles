set fish_greeting ""

# fastfetch on shell startup — skip when terminal too narrow (multi-window split,
# tmux pane, ssh, etc.) since otaku preset needs ~110 cols for image + modules.
if status is-interactive
    set -l _cols (tput cols 2>/dev/null; or echo 0)
    if test "$_cols" -ge 110
        fastfetch --config ~/.config/fastfetch/config.jsonc
    end
end

alias ls "eza"
alias la "eza -A"
alias ll "eza -l"
alias lla "eza -lA"
alias sg "ast-grep"
alias g git
alias c clear
alias vim nvim
alias rg "rg --hyperlink-format=kitty"
alias lg lazygit
alias claude "claude --dangerously-skip-permissions"
alias kimi "kimi --yolo"
alias "ca" "claude agents --dangerously-skip-permissions"

set -gx EDITOR nvim

set -gx PATH bin $PATH
set -gx PATH ~/bin $PATH
set -gx PATH ~/.local/bin $PATH
set -gx PATH ~/.local/share/bob/nvim-bin $PATH
set -gx PATH ~/.n/bin $PATH
set -x N_PREFIX $HOME/.n
set -gx PATH node_modules/.bin $PATH

set -gx GOPATH $HOME/go
set -gx PATH $GOPATH/bin $PATH

set -g JULIAPATH $HOME/.juliaup
set -gx PATH $JULIAPATH/bin $PATH

# Auto-start Hyprland on TTY1
if status is-login
    if test (tty) = "/dev/tty1"
        exec start-hyprland
    end
end

set -x N_PREFIX "$HOME/n"; contains "$N_PREFIX/bin" $PATH; or set -a PATH "$N_PREFIX/bin"  # Added by n-install (see http://git.io/n-install-repo).

set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

