#!/usr/bin/env bash
# Install latest stable Neovim (user-local) and link the NvChad-based config.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

require_ubuntu

NVIM_PREFIX="$HOME/.local/nvim"   # self-contained install dir
NVIM_BIN="$HOME/.local/bin/nvim"

install_neovim() {
  local a; a="$(arch)"
  local asset
  case "$a" in
    x86_64) asset="nvim-linux-x86_64" ;;
    arm64)  asset="nvim-linux-arm64" ;;
    *) warn "unsupported arch '$a' — install neovim manually"; return 1 ;;
  esac

  step "Installing latest stable Neovim ($asset)"
  local tmp; tmp="$(mktemp -d)"
  local url="https://github.com/neovim/neovim/releases/latest/download/${asset}.tar.gz"

  if ! download "$url" "$tmp/nvim.tar.gz"; then
    warn "download failed; falling back to apt neovim"
    run_root apt-get install -y neovim || die "could not install neovim"
    rm -rf "$tmp"; return 0
  fi

  tar -xzf "$tmp/nvim.tar.gz" -C "$tmp"
  rm -rf "$NVIM_PREFIX"
  mkdir -p "$NVIM_PREFIX"
  cp -a "$tmp/$asset/." "$NVIM_PREFIX/"
  mkdir -p "$HOME/.local/bin"
  ln -sf "$NVIM_PREFIX/bin/nvim" "$NVIM_BIN"
  rm -rf "$tmp"
  success "neovim installed -> $NVIM_BIN"
}

# Reinstall only if missing or older than 0.10 (NvChad needs >= 0.10).
needs_install=1
if command_exists nvim; then
  ver="$(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo 0.0)"
  major="${ver%%.*}"; minor="${ver##*.}"
  if [ "$major" -gt 0 ] || { [ "$major" -eq 0 ] && [ "$minor" -ge 10 ]; }; then
    success "neovim $ver already present"
    needs_install=0
  fi
fi
[ "$needs_install" -eq 1 ] && install_neovim

# --- link the config ---
step "Linking NvChad config"
link_file "$DOTFILES_DIR/config/nvim" "$HOME/.config/nvim"

cat <<EOF

$(success "neovim module done")
Run '${C_BOLD}nvim${C_RESET}' once: lazy.nvim will bootstrap and NvChad will compile
its theme cache. Use ':MasonInstallAll' (if you add servers) and ':checkhealth'.
EOF
