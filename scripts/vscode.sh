#!/usr/bin/env bash
# Install VS Code from Microsoft's apt repo, link settings, install extensions.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

require_ubuntu

install_vscode() {
  if command_exists code; then
    success "VS Code already installed"
    return 0
  fi
  step "Adding Microsoft VS Code apt repository"
  # Make sure the tools we need to add the repo exist.
  run_root apt-get install -y wget gnupg apt-transport-https >/dev/null 2>&1 || true

  local keyring="/etc/apt/keyrings/packages.microsoft.gpg"
  local tmp; tmp="$(mktemp -d)"

  download "https://packages.microsoft.com/keys/microsoft.asc" "$tmp/microsoft.asc"
  gpg --dearmor < "$tmp/microsoft.asc" > "$tmp/packages.microsoft.gpg"
  run_root install -D -o root -g root -m 644 "$tmp/packages.microsoft.gpg" "$keyring"
  echo "deb [arch=amd64,arm64,armhf signed-by=$keyring] https://packages.microsoft.com/repos/code stable main" \
    | run_root tee /etc/apt/sources.list.d/vscode.list >/dev/null
  rm -rf "$tmp"

  step "Installing VS Code"
  run_root apt-get update -y
  run_root apt-get install -y code
  success "VS Code installed"
}

link_settings() {
  step "Linking VS Code settings"
  local user_dir="$HOME/.config/Code/User"
  link_file "$DOTFILES_DIR/vscode/settings.json"     "$user_dir/settings.json"
  link_file "$DOTFILES_DIR/vscode/keybindings.json"  "$user_dir/keybindings.json"
}

install_extensions() {
  local list="$DOTFILES_DIR/vscode/extensions.txt"
  [ -f "$list" ] || { warn "no extensions.txt; skipping"; return 0; }
  command_exists code || { warn "'code' not on PATH; skipping extensions"; return 0; }

  step "Installing VS Code extensions"
  # Read non-empty, non-comment lines.
  while IFS= read -r ext || [ -n "$ext" ]; do
    case "$ext" in
      ''|\#*) continue ;;
    esac
    if code --install-extension "$ext" --force >/dev/null 2>&1; then
      success "$ext"
    else
      warn "failed to install $ext"
    fi
  done < "$list"
}

install_vscode
link_settings
install_extensions

success "vscode module done"
