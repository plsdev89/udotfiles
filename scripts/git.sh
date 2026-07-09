#!/usr/bin/env bash
# Link the global git config and create a local file for your identity.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# The gitconfig uses delta as the pager/diff filter; make sure it's present.
if ! command_exists delta; then
  step "Installing git-delta (used by gitconfig)"
  run_root apt-get install -y git-delta >/dev/null 2>&1 \
    && success "git-delta installed" \
    || warn "could not install git-delta — diffs will fall back if delta is missing"
fi

step "Linking git config"
link_file "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"

# Create an untracked local file for name/email if it doesn't exist yet.
local_cfg="$HOME/.gitconfig.local"
if [ ! -f "$local_cfg" ]; then
  step "Creating $local_cfg (fill in your identity)"
  cat > "$local_cfg" <<'EOF'
# Local, machine-specific git settings (NOT tracked by dotfiles).
# Fill in your details below.
[user]
	name = plsdev89
	email = plsdev89@gmail.com

# Optional: sign commits
# [user]
# 	signingkey = <key>
# [commit]
# 	gpgsign = true
EOF
  warn "Edit $local_cfg to set your git user.name / user.email"
else
  success "$local_cfg already exists"
fi

success "git module done"
