#!/usr/bin/env bash
# Set up zsh: antidote (manages oh-my-zsh plugins) + starship prompt + configs.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

require_ubuntu

# Ensure zsh exists (packages module normally handles this).
if ! command_exists zsh; then
  step "Installing zsh"
  run_root apt-get update -y
  run_root apt-get install -y zsh
fi

# --- antidote (plugin manager) ---
ANTIDOTE_DIR="$HOME/.antidote"
if [ -d "$ANTIDOTE_DIR/.git" ]; then
  step "Updating antidote"
  git -C "$ANTIDOTE_DIR" pull --ff-only --quiet || warn "antidote update skipped"
else
  step "Installing antidote"
  git clone --depth=1 https://github.com/mattmc3/antidote.git "$ANTIDOTE_DIR"
fi
success "antidote ready"

# --- starship prompt ---
if command_exists starship; then
  success "starship already installed"
else
  step "Installing starship"
  mkdir -p "$HOME/.local/bin"
  if command_exists curl; then
    curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
  else
    download https://starship.rs/install.sh /tmp/starship-install.sh
    sh /tmp/starship-install.sh -y -b "$HOME/.local/bin"
  fi
  success "starship installed"
fi

# --- symlink config files ---
step "Linking zsh + starship config"
link_file "$DOTFILES_DIR/zsh/.zshrc"            "$HOME/.zshrc"
link_file "$DOTFILES_DIR/zsh/.zsh_plugins.txt"  "$HOME/.zsh_plugins.txt"
link_file "$DOTFILES_DIR/config/starship.toml"  "$HOME/.config/starship.toml"

# Pre-generate the antidote static plugin file so the first shell is fast.
step "Pre-building antidote plugin bundle"
if zsh -ic 'source ~/.antidote/antidote.zsh; antidote bundle < ~/.zsh_plugins.txt > ~/.zsh_plugins.zsh' 2>/dev/null; then
  success "plugin bundle generated"
else
  warn "could not pre-build bundle; it will build on first shell start"
fi

# --- make zsh the default shell ---
ZSH_PATH="$(command -v zsh)"
if [ "${SHELL:-}" != "$ZSH_PATH" ]; then
  step "Setting zsh as the default shell"
  if grep -q "$ZSH_PATH" /etc/shells 2>/dev/null || run_root sh -c "echo '$ZSH_PATH' >> /etc/shells"; then :; fi
  if chsh -s "$ZSH_PATH" 2>/dev/null; then
    success "default shell set to zsh (re-login to take effect)"
  else
    warn "chsh failed; run manually: chsh -s $ZSH_PATH"
  fi
fi

success "zsh module done"
