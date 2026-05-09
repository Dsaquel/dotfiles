function fish_user_key_bindings
  fish_vi_key_bindings

  bind -M insert \cl forward-char
  # prevent kitty from closing when typing Ctrl-D (EOF)
  bind -M insert \cd delete-char

end

fzf_configure_bindings --directory=\cf

fzf --fish | source
