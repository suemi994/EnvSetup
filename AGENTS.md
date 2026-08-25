# AGENTS.md

## 1. Overview 

This repository automates Linux dev-environment setup on CentOS/RHEL (dnf) and Debian/Ubuntu (apt). A single POSIX-sh entry script (`scripts/setup.sh`) provisions shells, terminal tooling, programming languages, Neovim, Claude Code, and Docker, reusing dotfiles stored in this repo.

Core stack:

- **Shell**: POSIX `sh` with bash-only `declare -A` package maps (`scripts/setup.sh`, ~850 lines)
- **Neovim config**: Lua, Lazy.nvim plugin manager (`neovim/init.lua`, `neovim/lua/`)
- **Dotfiles**: `conf/` (zshrc, tmux.conf, clangd), `claude/` (claude-code-router template)
- **CI-style validation**: Dockerfiles for Debian bullseye and CentOS test containers

## 2. Quick Commands

```sh
# Run a specific setup subcommand
ROOT_DIR=$HOME bash scripts/setup.sh <command>
# Commands: env | zsh | tmux | vpn | nvim | cpp | rust | golang |
#           python | lua | nodejs | pi | mcp <agent...> | claude | docker | all

# Build and run the Debian test container
docker build -f Dockerfile.debian -t setup-debian . && docker run -it setup-debian

# Build and run the CentOS test container
docker build -f Dockerfile.centos -t setup-centos . && docker run -it setup-centos

# Full setup inside a clean container for validation
ROOT_DIR=/home/testuser bash scripts/setup.sh all

# Reload shell config after zshrc changes
source ~/.zshrc
```

No linter/formatter or test runner is configured — 待补充.

## 3. Directory Structure

```
scripts/setup.sh            # Single entry point: detect_distribution(), init_package_manager(),
                            # PACKAGE_MAPS, one setup_<name>() per subcommand (including Pi),
                            # main case dispatch
neovim/init.lua             # Neovim entry; requires lua/conf.lua etc.
neovim/lua/keymap.lua       # All keymaps (with desc fields)
neovim/lua/autocmd.lua      # Autocommands
neovim/lua/conf.lua         # Base editor options
neovim/lua/modules/         # Plugin specs, one file per concern:
                            #   ui.lua, editor.lua, cmp.lua, assist.lua
neovim/install.sh           # Standalone nvim installer
neovim/lazy-lock.json       # Plugin version lockfile (gitignored)
conf/zshrc                  # zsh config (managed via upsert helpers)
conf/tmux.conf              # tmux config (+ tmux_osx.conf variant)
conf/clangd                 # clangd LSP config
claude/claude-code-router.json.template  # Claude Code router template
Dockerfile.debian           # Debian test container (user: testuser, ROOT_DIR=/home/testuser)
Dockerfile.centos           # CentOS test container
CLAUDE.md                   # Pointer to this file (@AGENTS.md)
```

## 4. Code Style & Conventions

**Shell** (`scripts/setup.sh`):

- Shebang `#! /bin/sh`; ⚠️ note `declare -A` is a bashism kept intentionally for package maps
- 4-space indentation
- Functions: `snake_case` (e.g. `setup_zsh`, `detect_distribution`, `install_if_not_found`)
- Globals: `UPPER_CASE` (`PACKAGE_MANAGER`, `INSTALL_CMD`, `ROOT_DIR`)
- Locals declared with `local lower_case`
- Section dividers: `# ====...====` comment blocks
- Distribution logic centralized in `detect_distribution()` + `init_package_manager()`; new packages go into `PACKAGE_MAPS` as `"generic centos_pkg debian_pkg"` pairs, never hard-coded per distro
- Prefer the existing helpers `install_if_not_found`, `check_installed`, `upsert_env`, `upsert_conf` over ad-hoc logic

**Lua** (`neovim/lua/*`):

- 4-space indentation; `snake_case` for functions and modules
- Plugin specs live in `neovim/lua/modules/`, one file per concern
- Keymaps only in `keymap.lua`, each with an explicit `desc`
- Configs passed via `config = function() require("modules.xxx") ... end` style consistent with existing files

## 5. NEVER Rules

- 🚫 NEVER manually edit generated artifacts outside the repo: `~/.zshrc`, `~/.tmux.conf`, nvim runtime dirs, or anything `setup.sh` writes to `$ROOT_DIR`
- 🚫 NEVER bypass `PACKAGE_MAPS` / `get_package_names()` by hard-coding distro-specific package names inside a `setup_*` function
- 🚫 NEVER commit secrets, API keys, or tokens (the claude router template must stay a `.template`)
- 🚫 NEVER edit build/vendored dirs: `neovim/plugged*` (gitignored), `*/lazy-lock.json` is gitignored — don't force-add it
- 🚫 NEVER break POSIX intent of `setup.sh`: no arrays, `[[ ]]`, or other bashisms outside the already-bashism-tolerated map section
- 🚫 Don't skip container validation before changing distro-detection or install logic
- ✅ Test every changed subcommand individually before running `all`

## 6. Git Workflow

- Branch from main; keep commits scoped to one component (`setup`, `nvim`, `scripts`, docs)
- Conventional Commits (matches history):

```text
feat(setup): add docker setup support
fix(nvim): correct LSP configuration path
refactor(scripts): split setup_claude into smaller functions
docs: add repository guidelines
```

- PRs should state what changed and which distros (Debian/CentOS) were tested
- Keep `CLAUDE.md` as a one-line pointer to `@AGENTS.md`

## 7. Common Tasks

**Add a new package to an existing setup step**
Add it to the relevant `PACKAGE_MAPS` entry (`"generic centos_name debian_name"`); both distro names are required.

**Add a new subcommand**
1. Write `setup_<name>()` following the existing helper style
2. Register a `"<name>")` branch in the main `while true; do case` dispatch near line 760
3. Decide whether it belongs in the `all)` aggregate list
4. Validate in both Docker containers

**Add a Neovim plugin**
Edit the appropriate `neovim/lua/modules/<concern>.lua` spec; keymaps go in `keymap.lua` with `desc`. Verify with `:Lazy` and `:checkhealth`.

**Test a change**

```sh
# Pi and its configured extension packages
ROOT_DIR=$HOME bash scripts/setup.sh pi

docker build -f Dockerfile.debian -t setup-debian . && docker run -it setup-debian
# inside container:
ROOT_DIR=/home/testuser bash backup/scripts/setup.sh <command>
```

Repeat with `Dockerfile.centos`. For Neovim changes, launch `nvim` and confirm plugins load without errors.
