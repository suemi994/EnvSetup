# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a comprehensive development environment setup repository (`EnvSetup`) designed to configure a full-featured development workspace across multiple programming languages and tools. It provides automated setup scripts for Linux distributions (CentOS/RHEL and Debian/Ubuntu) with a focus on creating a portable, consistent development environment.

## Common Development Commands

### Environment Setup
```bash
# Complete environment setup on CentOS/RHEL
ROOT_DIR=$HOME bash scripts/setup_centos.sh all

# Component-by-component setup
bash scripts/setup_centos.sh zsh      # Shell configuration
bash scripts/setup_centos.sh tmux     # Terminal multiplexer
bash scripts/setup_centos.sh nvim     # Neovim IDE
bash scripts/setup_centos.sh cpp      # C++ development
bash scripts/setup_centos.sh rust     # Rust development
bash scripts/setup_centos.sh golang   # Go development
bash scripts/setup_centos.sh python   # Python development

# Debian/Ubuntu equivalent
ROOT_DIR=$HOME bash scripts/setup_debian.sh all
```

### Neovim Development
```bash
# Install/update plugins
nvim +LazyInstall +Lazy sync

# Key development shortcuts in neovim
:Diffview                # Git diff viewer
:Telescope find_files    # File finder
:LspRestart             # Restart LSP servers
:ChatGPT                # AI assistance (if configured)
:Avante                 # AI coding assistant (if configured)
```

### Terminal & Shell Workflow
```bash
tmux new-session -A -s main    # Attach/create main tmux session
vpn                           # Enable proxychains for network access
gco <branch>                  # Git checkout (alias)
gstat                         # Git status (alias)
glog                          # Git log (alias)
```

## Architecture Overview

### Core Components Structure

1. **Shell & Terminal** (`/conf/`):
   - `zshrc` - Zsh configuration with Oh My Zsh, custom aliases, and auto-tmux integration
   - `tmux.conf` - Main tmux configuration with Ctrl+x prefix, TPM plugins
   - `tmux_osx.conf` - macOS-specific tmux overrides

2. **Neovim IDE** (`/neovim/`):
   - `init.lua` - Entry point and plugin manager initialization
   - `lua/conf.lua` - Main neovim configuration (LSP, completion, keymaps)
   - `lua/modules/` - Modular plugin configurations:
     - `editor.lua` - Core editor enhancements (346 lines)
     - `ui.lua` - UI and theme setup (406 lines)
     - `cmp.lua` - Completion system (182 lines)
     - `assist.lua` - AI assistance tools (92 lines)
   - `autoload/ssh_clipboard.vim` - SSH clipboard integration

3. **Language Support**:
   - **C/C++**: Clangd LSP, clang-tidy, cmake integration via `/conf/clangd/config.yaml`
   - **Rust**: rustup, cargo, rust-analyzer integration
   - **Go**: Go toolchain with gopls LSP
   - **Python**: python-lsp-server integration
   - **Lua**: Lua development with luarocks

4. **Claude Integration** (`/claude/`):
   - `mcp/` - Model Context Protocol setup
   - `skills/` - Claude skills configuration

### Configuration Management Pattern

The repository uses a **symlink-based installation approach**:
- Configuration files are stored in the repository
- Setup scripts create symbolic links to `$HOME` locations
- Existing configurations are backed up before replacement
- Supports cross-platform variations (Linux vs macOS)

### Modular Plugin Architecture

Neovim follows a **category-based module structure**:
- **Editor modules**: Core editing functionality, LSP, diagnostics
- **UI modules**: Theme, statusline, file explorer, visual enhancements
- **Completion modules**: nvim-cmp with multiple sources (LSP, snippets, paths)
- **Assist modules**: AI coding assistants (ChatGPT.nvim, Avante.nvim, Codeium)

### Development Environment Features

- **Automatic tmux integration**: Shell automatically enters tmux sessions
- **Session persistence**: tmux resurrect/continuum for session restoration
- **SSH clipboard support**: Seamless clipboard sharing over SSH connections
- **Git integration**: Comprehensive git aliases and neovim git plugins
- **Multi-language LSP**: Unified LSP configuration across supported languages
- **AI-assisted development**: Configurable AI tools for coding assistance

## Key Technical Details

### LSP Configuration
- Language servers are configured in `lua/conf.lua` with unified settings
- Uses nvim-lspconfig with server-specific overrides
- Automatic LSP server installation and management

### Plugin Management
- Uses **Lazy.nvim** for efficient plugin loading and management
- Plugins are organized by functional category in separate modules
- Lazy loading implemented for optimal startup performance

### Build System Integration
- **CMake**: Primary build system with language server support
- **Ninja**: Fast build system integration
- Cross-language build tools: Automake/Autoconf, Cargo, Go build

### Cross-Platform Support
- Distribution-specific setup scripts handle package manager differences
- Conditional configuration loading based on OS detection
- Unified configuration structure with platform-specific overrides

## Recent Focus Areas

Based on git history, recent development emphasizes:
- Claude AI integration and neovim plugin support
- Enhanced C++ development with CMake and clang-tidy
- UI improvements and performance optimizations
- Cross-platform compatibility enhancements
- Network resilience features (SSH keep-alive, proxy support)

## Working Effectively in This Repository

1. **Initial Setup**: Run the appropriate distribution script for complete environment setup
2. **Development Workflow**: Use tmux for session management, neovim for development, git aliases for version control
3. **Configuration Changes**: Modify files in repository, then run setup scripts to apply changes
4. **Plugin Management**: Use `:Lazy` in neovim for plugin operations
5. **AI Assistance**: AI tools are integrated but require configuration of API keys