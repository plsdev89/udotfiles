#!/usr/bin/env bash
# Shared helpers for the dotfiles installer.
# This file is meant to be sourced, not executed directly.

# --- Resolve the dotfiles root regardless of where we're called from ---
# scripts/ lives directly under the repo root.
if [ -z "${DOTFILES_DIR:-}" ]; then
  _lib_source="${BASH_SOURCE[0]}"
  _lib_dir="$(cd "$(dirname "$_lib_source")" && pwd)"
  DOTFILES_DIR="$(cd "$_lib_dir/.." && pwd)"
fi
export DOTFILES_DIR

# --- Colors (disabled when not a TTY) ---
if [ -t 1 ]; then
  C_RESET="\033[0m"; C_RED="\033[0;31m"; C_GREEN="\033[0;32m"
  C_YELLOW="\033[0;33m"; C_BLUE="\033[0;34m"; C_BOLD="\033[1m"
else
  C_RESET=""; C_RED=""; C_GREEN=""; C_YELLOW=""; C_BLUE=""; C_BOLD=""
fi

info()    { printf "${C_BLUE}==>${C_RESET} %s\n" "$*"; }
step()    { printf "\n${C_BOLD}${C_BLUE}::${C_RESET}${C_BOLD} %s${C_RESET}\n" "$*"; }
success() { printf "${C_GREEN}✓${C_RESET} %s\n" "$*"; }
warn()    { printf "${C_YELLOW}!${C_RESET} %s\n" "$*" >&2; }
error()   { printf "${C_RED}✗ %s${C_RESET}\n" "$*" >&2; }
die()     { error "$*"; exit 1; }

# --- Small utilities ---
command_exists() { command -v "$1" >/dev/null 2>&1; }

# Normalized CPU arch: x86_64 | arm64
arch() {
  case "$(uname -m)" in
    x86_64|amd64) echo "x86_64" ;;
    aarch64|arm64) echo "arm64" ;;
    *) uname -m ;;
  esac
}

require_ubuntu() {
  if ! command_exists apt-get; then
    die "This installer targets Ubuntu/Debian (apt-get not found)."
  fi
}

# sudo wrapper that still works when already root
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  if command_exists sudo; then SUDO="sudo"; fi
fi
run_root() {
  if [ -n "$SUDO" ]; then $SUDO "$@"; else "$@"; fi
}

# --- Symlink management ---
# link_file <source> <target>
# Backs up an existing real file/dir at <target>, then symlinks source -> target.
link_file() {
  local src="$1" dst="$2"
  [ -e "$src" ] || { warn "source missing, skipping link: $src"; return 1; }
  mkdir -p "$(dirname "$dst")"

  if [ -L "$dst" ]; then
    local current
    current="$(readlink "$dst")"
    if [ "$current" = "$src" ]; then
      success "linked (already): $dst"
      return 0
    fi
    rm -f "$dst"
  elif [ -e "$dst" ]; then
    local backup="${dst}.bak.$(date +%Y%m%d%H%M%S)"
    warn "backing up existing $dst -> $backup"
    mv "$dst" "$backup"
  fi

  ln -s "$src" "$dst"
  success "linked: $dst -> $src"
}

# Download a URL to a path using curl or wget (whichever exists).
download() {
  local url="$1" out="$2"
  if command_exists curl; then
    curl -fsSL "$url" -o "$out"
  elif command_exists wget; then
    wget -qO "$out" "$url"
  else
    die "Neither curl nor wget is available to download $url"
  fi
}

# Fetch the latest release tag for a GitHub repo (e.g. jesseduffield/lazygit).
github_latest_tag() {
  local repo="$1"
  local api="https://api.github.com/repos/${repo}/releases/latest"
  if command_exists curl; then
    curl -fsSL "$api"
  else
    download "$api" /dev/stdout
  fi | grep -m1 '"tag_name"' | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/'
}
