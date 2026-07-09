#!/usr/bin/env bash
# Install base apt packages, modern CLI tools, and a Nerd Font.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

require_ubuntu

# Core build/runtime + the tools our zsh config wires up.
APT_PACKAGES=(
  # essentials
  zsh git curl wget unzip tar xz-utils
  ca-certificates gnupg software-properties-common
  build-essential fontconfig
  # nice everyday CLI tools
  ripgrep fd-find bat eza fzf zoxide git-delta
  htop tree jq
)

step "apt update"
run_root apt-get update -y

step "Installing apt packages"
# Install one-by-one so a single unavailable package doesn't abort everything.
for pkg in "${APT_PACKAGES[@]}"; do
  if run_root apt-get install -y --no-install-recommends "$pkg" >/dev/null 2>&1; then
    success "$pkg"
  else
    warn "could not install '$pkg' (not in repos?) — skipping"
  fi
done

# Ubuntu ships fd as 'fdfind' and bat as 'batcat'. Add friendlier names in ~/.local/bin.
mkdir -p "$HOME/.local/bin"
if command_exists fdfind && ! command_exists fd; then
  ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
  success "linked fd -> fdfind"
fi
if command_exists batcat && ! command_exists bat; then
  ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
  success "linked bat -> batcat"
fi

# --- Nerd Font (needed for starship + NvChad icons) ---
install_nerd_font() {
  local font="JetBrainsMono"
  local font_dir="$HOME/.local/share/fonts"
  if fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd Font"; then
    success "Nerd Font already installed"
    return 0
  fi
  step "Installing $font Nerd Font"
  mkdir -p "$font_dir"
  local tmp; tmp="$(mktemp -d)"
  local url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.zip"
  if download "$url" "$tmp/${font}.zip"; then
    unzip -o -q "$tmp/${font}.zip" -d "$font_dir/${font}NerdFont" \
      -x "*.md" "*.txt" || true
    fc-cache -f >/dev/null 2>&1 || true
    success "Installed $font Nerd Font"
  else
    warn "Could not download Nerd Font; install one manually for icons."
  fi
  rm -rf "$tmp"
}
install_nerd_font

success "packages module done"
