#!/usr/bin/env bash
# full-stack dev stack: pyenv, nvm, PostgreSQL, Redis, gh, zellij.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

require_ubuntu

PYTHON_VERSION="${PYTHON_VERSION:-3.12.7}"
NODE_VERSION="${NODE_VERSION:-24}"
NVM_VERSION="${NVM_VERSION:-0.40.5}"
PG_MAJOR="${PG_MAJOR:-16}"

# ---------------------------------------------------------------------------
# pyenv build dependencies
# ---------------------------------------------------------------------------
PYENV_BUILD_DEPS=(
  make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev
  libsqlite3-dev llvm libncursesw5-dev tk-dev libxml2-dev libxmlsec1-dev
  libffi-dev liblzma-dev
)

step "Installing pyenv build dependencies"
run_root apt-get update -y
for pkg in "${PYENV_BUILD_DEPS[@]}"; do
  if run_root apt-get install -y --no-install-recommends "$pkg" >/dev/null 2>&1; then
    success "$pkg"
  else
    warn "could not install '$pkg' — skipping"
  fi
done

# ---------------------------------------------------------------------------
# pyenv + Python + Poetry
# ---------------------------------------------------------------------------
setup_pyenv() {
  export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
  export PATH="$PYENV_ROOT/bin:$PATH"

  if [ -d "$PYENV_ROOT" ]; then
    success "pyenv already installed"
  else
    step "Installing pyenv"
    curl -fsSL https://pyenv.run | bash
    success "pyenv installed -> $PYENV_ROOT"
  fi

  # pyenv init for this bash session (installer runs under bash).
  # shellcheck disable=SC1090
  eval "$(pyenv init - bash)"

  if pyenv versions --bare 2>/dev/null | grep -qx "$PYTHON_VERSION"; then
    success "Python $PYTHON_VERSION already installed"
  else
    step "Installing Python $PYTHON_VERSION (this can take a few minutes)"
    pyenv install "$PYTHON_VERSION"
    success "Python $PYTHON_VERSION installed"
  fi

  if ! command_exists poetry; then
    step "Installing Poetry"
    pyenv shell "$PYTHON_VERSION"
    python -m pip install --upgrade pip
    python -m pip install poetry
    pyenv shell --unset
    success "Poetry installed"
  else
    success "Poetry already installed"
  fi
}
setup_pyenv

# ---------------------------------------------------------------------------
# nvm + Node + Yarn (via corepack)
# ---------------------------------------------------------------------------
setup_nvm() {
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

  if [ -s "$NVM_DIR/nvm.sh" ]; then
    success "nvm already installed"
  else
    step "Installing nvm v$NVM_VERSION"
    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh" | bash
    success "nvm v$NVM_VERSION installed"
  fi

  # shellcheck disable=SC1090
  source "$NVM_DIR/nvm.sh"

  if nvm ls "$NODE_VERSION" >/dev/null 2>&1; then
    success "Node $NODE_VERSION already installed"
  else
    step "Installing Node $NODE_VERSION"
    nvm install "$NODE_VERSION"
    success "Node $NODE_VERSION installed"
  fi

  nvm alias default "$NODE_VERSION" >/dev/null 2>&1 || true
  nvm use default >/dev/null 2>&1 || nvm use "$NODE_VERSION"

  if command_exists corepack; then
    step "Enabling Yarn via corepack"
    corepack enable yarn >/dev/null 2>&1 || corepack enable
    success "corepack / yarn ready ($(yarn -v 2>/dev/null || echo 'enabled'))"
  else
    warn "corepack not found — install a recent Node and run: corepack enable yarn"
  fi
}
setup_nvm

# ---------------------------------------------------------------------------
# PostgreSQL (PGDG) + pgvector
# ---------------------------------------------------------------------------
setup_postgresql() {
  step "Setting up PostgreSQL $PG_MAJOR (PGDG)"

  if ! run_root test -f /usr/share/postgresql-common/pgdg/apt.postgresql.org.gpg; then
    run_root install -d /usr/share/postgresql-common/pgdg
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
      | run_root gpg --dearmor -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.gpg
    echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.gpg] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" \
      | run_root tee /etc/apt/sources.list.d/pgdg.list >/dev/null
    run_root apt-get update -y
  fi

  for pkg in "postgresql-${PG_MAJOR}" "postgresql-${PG_MAJOR}-pgvector"; do
    if run_root apt-get install -y --no-install-recommends "$pkg" >/dev/null 2>&1; then
      success "$pkg"
    else
      warn "could not install '$pkg' — skipping"
    fi
  done

  run_root systemctl enable postgresql >/dev/null 2>&1 || true
  run_root systemctl start postgresql >/dev/null 2>&1 || true
  success "PostgreSQL service enabled"
}
setup_postgresql

# ---------------------------------------------------------------------------
# Redis
# ---------------------------------------------------------------------------
setup_redis() {
  step "Installing Redis"
  if run_root apt-get install -y --no-install-recommends redis-server >/dev/null 2>&1; then
    run_root systemctl enable redis-server >/dev/null 2>&1 || \
      run_root systemctl enable redis >/dev/null 2>&1 || true
    run_root systemctl start redis-server >/dev/null 2>&1 || \
      run_root systemctl start redis >/dev/null 2>&1 || true
    success "Redis installed and started"
  else
    warn "could not install redis-server — skipping"
  fi
}
setup_redis

# ---------------------------------------------------------------------------
# OpenSSH server (remote access / agent forwarding)
# ---------------------------------------------------------------------------
setup_ssh_server() {
  step "Installing OpenSSH server"
  if run_root apt-get install -y --no-install-recommends openssh-server >/dev/null 2>&1; then
    run_root systemctl enable ssh >/dev/null 2>&1 || true
    run_root systemctl start ssh >/dev/null 2>&1 || true
    success "OpenSSH server enabled"
  else
    warn "could not install openssh-server — skipping"
  fi
}
setup_ssh_server

# ---------------------------------------------------------------------------
# GitHub CLI (gh)
# ---------------------------------------------------------------------------
setup_gh() {
  if command_exists gh; then
    success "gh already installed ($(gh --version | head -1))"
    return 0
  fi

  step "Installing GitHub CLI (gh)"
  run_root install -d -m 755 /etc/apt/keyrings
  local keyring="/etc/apt/keyrings/githubcli-archive-keyring.gpg"
  if ! run_root test -f "$keyring"; then
    local tmp; tmp="$(mktemp)"
    download "https://cli.github.com/packages/githubcli-archive-keyring.gpg" "$tmp"
    run_root tee "$keyring" < "$tmp" >/dev/null
    run_root chmod go+r "$keyring"
    rm -f "$tmp"
    echo "deb [arch=$(dpkg --print-architecture) signed-by=${keyring}] https://cli.github.com/packages stable main" \
      | run_root tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    run_root apt-get update -y
  fi

  if run_root apt-get install -y gh >/dev/null 2>&1; then
    success "gh installed — run 'gh auth login' to authenticate"
  else
    warn "could not install gh — skipping"
  fi
}
setup_gh

# ---------------------------------------------------------------------------
# zellij (terminal multiplexer)
# ---------------------------------------------------------------------------
install_zellij() {
  step "Installing zellij"
  local a; a="$(arch)"
  local asset_arch
  case "$a" in
    x86_64) asset_arch="x86_64-unknown-linux-musl" ;;
    arm64)  asset_arch="aarch64-unknown-linux-musl" ;;
    *) warn "unsupported arch '$a' for zellij"; return 1 ;;
  esac

  local tag version
  tag="$(github_latest_tag zellij-org/zellij || true)"
  [ -n "$tag" ] || { warn "could not resolve latest zellij tag"; return 1; }
  version="${tag#v}"

  if command_exists zellij; then
    local cur
    cur="$(zellij --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo '')"
    if [ "$cur" = "$version" ]; then
      success "zellij $version already installed"
      return 0
    fi
  fi

  local tmp; tmp="$(mktemp -d)"
  local url="https://github.com/zellij-org/zellij/releases/download/${tag}/zellij-${asset_arch}.tar.xz"
  if ! download "$url" "$tmp/zellij.tar.xz"; then
    warn "zellij download failed ($url)"
    rm -rf "$tmp"; return 1
  fi
  tar -xJf "$tmp/zellij.tar.xz" -C "$tmp" zellij
  mkdir -p "$HOME/.local/bin"
  install -m 755 "$tmp/zellij" "$HOME/.local/bin/zellij"
  rm -rf "$tmp"
  success "zellij $version installed -> ~/.local/bin/zellij"
}
install_zellij

success "dev module done"

cat <<EOF

Optional next steps (not automated):
  • Authenticate GitHub CLI:  ${C_BOLD}gh auth login${C_RESET}
  • Create a test database:   ${C_BOLD}createdb test${C_RESET}
EOF
