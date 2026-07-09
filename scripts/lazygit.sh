#!/usr/bin/env bash
# Install the latest lazygit release (binary) and link its config.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

require_ubuntu

install_lazygit() {
  step "Installing lazygit"
  local a; a="$(arch)"
  local asset_arch
  case "$a" in
    x86_64) asset_arch="x86_64" ;;
    arm64)  asset_arch="arm64" ;;
    *) warn "unsupported arch '$a' for lazygit"; return 1 ;;
  esac

  local tag version
  tag="$(github_latest_tag jesseduffield/lazygit || true)"
  [ -n "$tag" ] || { warn "could not resolve latest lazygit tag"; return 1; }
  version="${tag#v}"

  if command_exists lazygit; then
    local cur
    cur="$(lazygit --version 2>/dev/null | grep -oE 'version=[0-9.]+' | cut -d= -f2 || echo '')"
    if [ "$cur" = "$version" ]; then
      success "lazygit $version already installed"
      return 0
    fi
  fi

  local tmp; tmp="$(mktemp -d)"
  local url="https://github.com/jesseduffield/lazygit/releases/download/${tag}/lazygit_${version}_Linux_${asset_arch}.tar.gz"
  if ! download "$url" "$tmp/lazygit.tar.gz"; then
    warn "lazygit download failed ($url)"
    rm -rf "$tmp"; return 1
  fi
  tar -xzf "$tmp/lazygit.tar.gz" -C "$tmp" lazygit
  mkdir -p "$HOME/.local/bin"
  install -m 755 "$tmp/lazygit" "$HOME/.local/bin/lazygit"
  rm -rf "$tmp"
  success "lazygit $version installed -> ~/.local/bin/lazygit"
}

install_lazygit

step "Linking lazygit config"
link_file "$DOTFILES_DIR/config/lazygit/config.yml" "$HOME/.config/lazygit/config.yml"

success "lazygit module done"
