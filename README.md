# dotfiles

Opinionated development environment for **Ubuntu 26.04**. One script installs the
tools and symlinks the configs.

What you get:

- **Terminal** — `zsh` + [oh-my-zsh](https://ohmyz.sh/) plugins managed by
  [antidote](https://antidote.sh), the [starship](https://starship.rs) prompt,
  autosuggestions, fast syntax highlighting, history substring search, and
  modern CLI tools (`eza`, `bat`, `ripgrep`, `fd`, `fzf`, `zoxide`, `delta`).
- **Dev stack** — [pyenv](https://github.com/pyenv/pyenv) (Python 3.12.7 +
  Poetry), [nvm](https://github.com/nvm-sh/nvm) (Node 24 + Yarn via corepack),
  PostgreSQL 16 + [pgvector](https://github.com/pgvector/pgvector), Redis,
  [GitHub CLI](https://cli.github.com) (`gh`), [zellij](https://zellij.dev),
  and OpenSSH server.
- **Neovim** — latest stable Neovim with a [NvChad](https://nvchad.com)-based
  config (treesitter, LSP, conform formatting, LazyGit integration).
- **VS Code** — installed from Microsoft's apt repo, with settings, keybindings,
  and a curated extension list.
- **LazyGit** — latest release with a themed config, wired into git and Neovim.

Everything is symlinked from this repo, so edits here are picked up live.

## Quick start

```bash
git clone https://github.com/<you>/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

Then open a new terminal (or run `exec zsh`) and open `nvim` once so plugins
bootstrap. Set your terminal font to **JetBrainsMono Nerd Font** (installed for
you) so icons render.

### Run only what you want

```bash
./install.sh --list              # show modules
./install.sh zsh neovim          # only the shell + editor
./install.sh packages            # just tools + Nerd Font
```

Modules run (in order) for a full install:
`packages git dev zsh neovim vscode lazygit`.

## Layout

```
dotfiles/
├── install.sh            # entry point
├── scripts/              # one installer per module + shared lib.sh
│   └── dev.sh            # pyenv, nvm, PostgreSQL, Redis, gh, zellij
├── config/
│   ├── starship.toml     # → ~/.config/starship.toml
│   ├── nvim/             # → ~/.config/nvim   (NvChad-based)
│   └── lazygit/          # → ~/.config/lazygit/config.yml
├── zsh/
│   ├── .zshrc            # → ~/.zshrc
│   ├── .zsh_plugins.txt  # → ~/.zsh_plugins.txt   (antidote plugin list)
│   └── aliases.zsh       # sourced by .zshrc
├── git/.gitconfig        # → ~/.gitconfig (identity lives in ~/.gitconfig.local)
└── vscode/               # → ~/.config/Code/User/{settings,keybindings}.json
```

## How the shell is wired

`oh-my-zsh`, `antidote`, and `starship` are combined the idiomatic way:

- **antidote** is the plugin manager. It loads oh-my-zsh's library and selected
  oh-my-zsh plugins (via `getantidote/use-omz`) _plus_ extra community plugins.
- **starship** is the prompt (oh-my-zsh themes are not used).

Edit the plugin list in [`zsh/.zsh_plugins.txt`](zsh/.zsh_plugins.txt); the
compiled bundle regenerates automatically on next shell start.

### Dev stack

The `dev` module mirrors a typical Ubuntu setup

| Tool           | Version / notes                                |
| -------------- | ---------------------------------------------- |
| pyenv + Python | 3.12.7 (override with `PYTHON_VERSION=…`)      |
| Poetry         | installed via pip into the pyenv Python        |
| nvm + Node     | 24 (override with `NODE_VERSION=…`)            |
| Yarn           | enabled via `corepack`                         |
| PostgreSQL     | 16 from PGDG, with `pgvector` extension        |
| Redis          | `redis-server`, enabled on boot                |
| gh             | GitHub CLI (run `gh auth login` after install) |
| zellij         | latest release → `~/.local/bin/zellij`         |

Shell integrations wired in [`.zshrc`](zsh/.zshrc):

- `pyenv init` and `nvm` sourcing
- SSH agent startup + auto-`ssh-add` for `~/.ssh/id_ed25519`

Optional env overrides when running the installer:

```bash
PYTHON_VERSION=3.12.7 NODE_VERSION=24 ./install.sh dev
```

## Customizing

- **Shell**: machine-specific tweaks go in `~/.zshrc.local` (untracked).
- **Git identity**: edit `~/.gitconfig.local` (created on first run).
- **Neovim**: it's a standard NvChad starter — edit `config/nvim/lua/*`.
  Install language servers/formatters with `:Mason`.
- **VS Code extensions**: add ids to `vscode/extensions.txt` and rerun
  `./install.sh vscode`.

## Notes

- The installer is **idempotent** and **backs up** any existing real file it
  would replace (e.g. `~/.zshrc` → `~/.zshrc.bak.<timestamp>`).
- Neovim and LazyGit are installed user-locally to `~/.local/bin` (latest stable
  releases), so they're newer than the apt versions.
- Line endings are forced to LF via `.gitattributes` so scripts work even if the
  repo is edited on Windows.
- Requires `sudo` for apt packages and the VS Code repo only.
