#!/usr/bin/env zsh
# ~/.zshrc — managed by dotfiles (https://github.com/<you>/dotfiles)

# Where the dotfiles repo lives (override by exporting DOTFILES before zsh starts).
export DOTFILES="${DOTFILES:-$HOME/dotfiles}"

# ---------------------------------------------------------------------------
# PATH
# ---------------------------------------------------------------------------
typeset -U path PATH                      # keep PATH entries unique
path=(
  "$HOME/.local/bin"
  "$HOME/bin"
  "/usr/local/bin"
  $path
)

# pyenv + nvm (dev module)
export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
[[ -d $PYENV_ROOT/bin ]] && path=("$PYENV_ROOT/bin" $path)

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"

export PATH
command -v pyenv >/dev/null && eval "$(pyenv init - zsh)"

# ---------------------------------------------------------------------------
# Environment
# ---------------------------------------------------------------------------
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less"
export LESS="-R"

# ---------------------------------------------------------------------------
# History
# ---------------------------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY        # record timestamps
setopt INC_APPEND_HISTORY      # write as commands are entered
setopt SHARE_HISTORY           # share across sessions
setopt HIST_IGNORE_DUPS        # don't record an entry that's a dup of the last
setopt HIST_IGNORE_ALL_DUPS    # delete older duplicates
setopt HIST_IGNORE_SPACE       # ignore commands that start with a space
setopt HIST_REDUCE_BLANKS      # trim superfluous blanks
setopt HIST_VERIFY             # show before running history expansions

# ---------------------------------------------------------------------------
# Shell behavior
# ---------------------------------------------------------------------------
setopt AUTO_CD                 # `dir` == `cd dir`
setopt AUTO_PUSHD              # cd pushes onto the dir stack
setopt PUSHD_IGNORE_DUPS
setopt INTERACTIVE_COMMENTS    # allow # comments in interactive shell
setopt NO_BEEP
setopt PROMPT_SUBST

# ---------------------------------------------------------------------------
# Plugins via antidote (loads oh-my-zsh libs/plugins + extras)
# ---------------------------------------------------------------------------
ANTIDOTE_DIR="${ZDOTDIR:-$HOME}/.antidote"
zsh_plugins="${ZDOTDIR:-$HOME}/.zsh_plugins"

if [[ -f "$ANTIDOTE_DIR/antidote.zsh" ]]; then
  # Regenerate the compiled plugin file whenever the list changes.
  if [[ ! "${zsh_plugins}.zsh" -nt "${zsh_plugins}.txt" ]]; then
    source "$ANTIDOTE_DIR/antidote.zsh"
    antidote bundle < "${zsh_plugins}.txt" > "${zsh_plugins}.zsh"
  fi
  source "${zsh_plugins}.zsh"
else
  print -P "%F{yellow}antidote not found — run the dotfiles installer (zsh module).%f"
fi

# ---------------------------------------------------------------------------
# Completion
# ---------------------------------------------------------------------------
# Plugins added their dirs to $fpath above; initialize completion now.
autoload -Uz compinit
# Refresh the dump at most once a day for faster startup.
if [[ -n "${ZDOTDIR:-$HOME}/.zcompdump"(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'   # case-insensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:descriptions' format '%F{blue}%d%f'

# history-substring-search key bindings (arrow keys)
bindkey '^[[A' history-substring-search-up    2>/dev/null
bindkey '^[[B' history-substring-search-down  2>/dev/null

# ---------------------------------------------------------------------------
# SSH agent (load ed25519 key when present)
# ---------------------------------------------------------------------------
if command -v ssh-agent >/dev/null; then
  if ! pgrep -u "$USER" ssh-agent >/dev/null 2>&1; then
    eval "$(ssh-agent -s)" >/dev/null
  fi
  [[ -f "$HOME/.ssh/id_ed25519" ]] && ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null
fi

# ---------------------------------------------------------------------------
# Prompt + tool integrations
# ---------------------------------------------------------------------------
command -v starship >/dev/null && eval "$(starship init zsh)"
command -v zoxide   >/dev/null && eval "$(zoxide init zsh)"

# fzf key bindings + completion (fzf >= 0.48 ships `fzf --zsh`).
if command -v fzf >/dev/null; then
  if fzf --zsh >/dev/null 2>&1; then
    source <(fzf --zsh)
  else
    [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]] && source /usr/share/doc/fzf/examples/key-bindings.zsh
    [[ -f /usr/share/doc/fzf/examples/completion.zsh   ]] && source /usr/share/doc/fzf/examples/completion.zsh
  fi
fi

# ---------------------------------------------------------------------------
# Aliases + local overrides
# ---------------------------------------------------------------------------
[[ -f "$DOTFILES/zsh/aliases.zsh" ]] && source "$DOTFILES/zsh/aliases.zsh"

# Machine-specific, untracked tweaks.
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
