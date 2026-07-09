#!/usr/bin/env bash
#
# dotfiles installer for Ubuntu 26.04
#
#   ./install.sh             # run everything
#   ./install.sh zsh nvim    # run only selected modules
#   ./install.sh --list      # show available modules
#   ./install.sh --help
#
# Modules: packages git dev zsh neovim vscode lazygit
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_DIR="$SCRIPT_DIR"
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/scripts/lib.sh"

ALL_MODULES=(packages git dev zsh neovim vscode lazygit)

usage() {
  cat <<EOF
${C_BOLD}dotfiles installer${C_RESET}

Usage:
  ./install.sh [options] [modules...]

Modules (run in this order when none are specified):
  packages   apt packages + modern CLI tools + Nerd Font
  git        ~/.gitconfig (with a local include for your identity)
  dev        pyenv, nvm, PostgreSQL, Redis, gh, zellij (+ OpenSSH server)
  zsh        zsh + oh-my-zsh (via antidote) + starship + plugins
  neovim     neovim (latest stable) + NvChad-based config
  vscode     VS Code (apt repo) + settings + extensions
  lazygit    lazygit (latest release) + config

Options:
  -l, --list   List modules and exit
  -h, --help   Show this help and exit

Examples:
  ./install.sh                # full setup
  ./install.sh zsh neovim     # just shell + editor
EOF
}

run_module() {
  local m="$1"
  local script="$SCRIPT_DIR/scripts/${m}.sh"
  [ -f "$script" ] || die "Unknown module: $m"
  step "Module: $m"
  # shellcheck disable=SC1090
  bash "$script"
}

main() {
  local modules=()
  while [ $# -gt 0 ]; do
    case "$1" in
      -h|--help) usage; exit 0 ;;
      -l|--list) printf '%s\n' "${ALL_MODULES[@]}"; exit 0 ;;
      -*) die "Unknown option: $1 (try --help)" ;;
      *) modules+=("$1") ;;
    esac
    shift
  done

  require_ubuntu

  if [ "${#modules[@]}" -eq 0 ]; then
    modules=("${ALL_MODULES[@]}")
  fi

  info "Dotfiles dir: $DOTFILES_DIR"
  info "Modules:      ${modules[*]}"

  local failed=()
  for m in "${modules[@]}"; do
    if ! run_module "$m"; then
      error "module '$m' failed — continuing with the rest"
      failed+=("$m")
    fi
  done

  step "All done"
  if [ "${#failed[@]}" -gt 0 ]; then
    warn "These modules reported errors: ${failed[*]}"
    warn "Re-run them individually, e.g.: ./install.sh ${failed[*]}"
  else
    success "Setup complete."
  fi
  cat <<EOF

Next steps:
  1. Start a new terminal (or run: ${C_BOLD}exec zsh${C_RESET}) to load the new shell.
  2. If zsh isn't your default shell yet, log out/in once (the installer
     attempts 'chsh -s \$(which zsh)').
  3. Open Neovim once (${C_BOLD}nvim${C_RESET}) and let NvChad/lazy.nvim bootstrap plugins.
  4. Make sure your terminal uses a Nerd Font (JetBrainsMono Nerd Font was installed).
EOF
}

main "$@"
