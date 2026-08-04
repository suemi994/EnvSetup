# Repository Guidelines

## Project Structure & Module Organization

This repository automates Linux dev-environment setup on CentOS/RHEL and Debian/Ubuntu.

```
scripts/setup.sh       # Universal setup entry point (multi-distro)
neovim/                # Neovim config (Lazy.nvim, Lua modules)
neovim/lua/modules/    # Plugin specs: ui, editor, cmp, assist
conf/                  # Dotfiles: zshrc, tmux.conf, clangd config
claude/                # Claude Code router template
Dockerfile.{debian,centos}  # Test containers for CI validation
```

`scripts/setup.sh` accepts subcommands (`env`, `zsh`, `nvim`, `cpp`, `rust`, `golang`, `python`, `claude`, `docker`, `all`). Run with `ROOT_DIR=$HOME bash scripts/setup.sh <command>`.

## Build, Test, and Development Commands

```sh
# Build and run the Debian test container
docker build -f Dockerfile.debian -t setup-debian . && docker run -it setup-debian

# Build and run the CentOS test container
docker build -f Dockerfile.centos -t setup-centos . && docker run -it setup-centos

# Run the full setup inside a container for validation
ROOT_DIR=/home/testuser bash scripts/setup.sh all
```

Docker images let you test the setup script in a clean environment without affecting your host machine.

## Coding Style & Naming Conventions

**Shell** (`scripts/setup.sh`):
- 4-space indentation
- Functions use `snake_case`; variables are `UPPER_CASE` for globals, `lower_case` for locals
- Section dividers use `# ====` comments
- Distribution logic is centralized in `detect_distribution()` and `init_package_manager()`

**Lua** (`neovim/lua/*`):
- 4-space indentation; `snake_case` for function and module names
- Plugin specs live in `neovim/lua/modules/`, one file per concern
- Keymaps are defined in `keymap.lua` with explicit `desc` fields

## Testing Guidelines

- Test changes inside Docker containers using the Dockerfiles provided.
- Validate each `setup.sh` subcommand individually before testing `all`.
- For Neovim changes, launch nvim and confirm plugins load without errors (`:Lazy` and `:checkhealth`).

## Commit & Pull Request Guidelines

Follow conventional commits as seen in the Git history:

```
feat(setup): add docker setup support
fix(nvim): correct LSP configuration path
refactor(scripts): split setup_claude into smaller functions
```

Keep commits scoped to one component at a time. PRs should include a brief description of what changed and which distros were tested.
