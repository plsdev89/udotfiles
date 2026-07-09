#!/usr/bin/env zsh
# Aliases + tiny helpers, sourced from .zshrc.

# --- listing (eza if available, else coreutils ls) -------------------------
if command -v eza >/dev/null; then
  alias ls='eza --group-directories-first --icons=auto'
  alias ll='eza -lh --group-directories-first --icons=auto --git'
  alias la='eza -lah --group-directories-first --icons=auto --git'
  alias lt='eza --tree --level=2 --icons=auto'
else
  alias ls='ls --color=auto'
  alias ll='ls -lh'
  alias la='ls -lah'
fi

# --- cat -> bat ------------------------------------------------------------
if command -v bat >/dev/null; then
  alias cat='bat --paging=never'
  export BAT_THEME="ansi"
fi

# --- editor ----------------------------------------------------------------
alias v='nvim'
alias vim='nvim'

# --- git / lazygit / zellij ------------------------------------------------
alias lg='lazygit'
alias g='git'
if command -v zellij >/dev/null; then
  alias zj='zellij'
fi

# --- safety / convenience --------------------------------------------------
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias mkdir='mkdir -p'
alias df='df -h'
alias du='du -h'
alias grep='grep --color=auto'

# Reload the shell config.
alias reload='exec zsh'

# mkdir + cd in one go.
mkcd() { mkdir -p "$1" && cd "$1"; }
