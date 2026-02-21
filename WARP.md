# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Overview

This is a modular, performance-optimized Zsh configuration system designed for the NOMAD workflow. The architecture emphasizes:
- **Modularity**: Each feature isolated in its own file
- **Portability**: Cross-platform (macOS, Linux, BSD) with intelligent environment detection
- **Performance**: Lazy loading, caching, PATH-based plugin system
- **Git-centric**: Custom workflow utilities for dotfiles and submodule management

The configuration lives in `~/.config/zsh` (ZDOTDIR) and is designed to work as a Git submodule within a parent `.config` repository.

## Build/Test/Development Commands

### Shell Management
```bash
# Reload shell configuration
source ~/.config/zsh/.zshrc
# OR
s

# Reload with debug output
ZSH_BOOT_DEBUG=true exec zsh
# OR
sd

# Profile startup performance
zsh -i -c exit
```

### Completions
```bash
# Rebuild completion cache (if completions not working)
rm -f ~/.config/zsh/.zcompdump*
compinit

# Refresh completions
compinit -i
```

### Plugin Management
```bash
# Update all plugins (manual)
cd ~/.config/zsh/plugins
for plugin in */; do
    (cd "$plugin" && git pull)
done

# View plugin update logs
pluglog  # Last 20 entries
tail -n 50 "$ZLOGDIR/plugin-manager.zlog"
```

### Logging & Debugging
```bash
# View boot logs
zlog  # Last 20 entries
tail -f "$ZLOGDIR/boot.zlog"

# View path exports log
cat ~/.config/zsh/logs/pathlog.zlog

# View all logs
ls ~/.config/zsh/logs/
```

### Git Utilities Testing
```bash
# Test suites are located in:
~/.config/docs/zsh/git/TEST.SUITE.*.zsh

# Example: Test conflict resolution
~/.config/docs/zsh/git/TEST.SUITE.06.autoConflictResolution.zsh
```

## Architecture

### Boot Sequence
The shell initialization follows a strict phase-based loading order (orchestrated by `.zshrc`):

1. **Phase 1** (`.zshenv` → `my.zshenv`): Set ZDOTDIR, XDG dirs, core environment
2. **Phase 2** (`env.zsh`): Load PATH, bootstrap utilities, source bootlog-handler
3. **Phase 3** (`lib/zsh-initgit.zsh`): Configure Git settings, detect GitHub/GitLab user
4. **Phase 4** (`zsh-optionrc`): Set Zsh options for interactive shells
5. **Phase 5** (Brew environment): Source `$BREWDOTS/.env`
6. **Phase 6** (`lib/keybinds.zsh`): Configure key bindings
7. **Phase 7** (`lib/plugin_manager.zsh`): Load custom plugin manager
8. **Phase 8** (`lib/zsh-init.zsh`): Load all modules, plugins, completions
9. **Phase 9** (`lib/zsh-fuzzy.zsh`): Initialize fzf and zoxide
10. **Phase 10**: Complete boot, generate zprof log

### Core Components

#### Plugin System (`lib/plugin_manager.zsh`)
Custom plugin manager with three primary functions:
- `zsh_add_plugin <github_repo>`: Auto-clones and sources plugins from GitHub
- `zsh_add_file <relative_path>`: Sources files from ZDOTDIR
- `zsh_add_completion <repo> [true]`: Adds completion scripts to fpath

Plugins are cloned to `$ZDOTDIR/plugins/` with `--depth=1` for speed. The manager auto-discovers `.plugin.zsh` or `.zsh` files.

#### Git Utilities (`git-utils/`)
Comprehensive Git workflow system for managing dotfiles and submodules:
- **Repository creation**: `grepo [msg] [name]` - Initialize and push to GitHub/GitLab
- **Submodule management**: `gsub`, `gunsub`, `gsync`, `gsync-all`, `gsub-all`
- **Security**: `gsecrets`, `gencrypt_setup`, `gshook` (pre-commit hook)
- **Utilities**: `git-genignore`, `git-toggle-remote`, `git-aliases`

All functions require `GITHUB_USER` or `GITLAB_USER` to be set. Uses `gh` or `glab` CLI for repo operations.

#### Prompt System (`prompt/`)
Standalone Git-aware prompt module with:
- Async rendering (<5ms)
- Clean/dirty status indicators
- Ahead/behind tracking
- Merge/rebase detection
- Virtual environment display

#### Library Files (`lib/`)
- `plugin_manager.zsh`: Plugin loading system
- `zsh-init.zsh`: Module orchestration
- `zsh-initgit.zsh`: Git environment setup
- `zsh-fuzzy.zsh`: fzf and zoxide integration
- `keybinds.zsh`: Key binding configuration
- `pathtools.zsh`: Intelligent PATH management without duplication

#### Utilities (`utils/`)
Standalone scripts added to PATH:
- `zsh-bootlog-handler`: Boot phase logging
- `zshlog`: Custom logging utility
- `history-toggle`: Switch between shared/private history
- `zsh-utils.zsh`: Shared utility functions
- `zshenv_report`: Environment variable debugging

### Configuration Files
- `.zshrc`: Main entry point, orchestrates all loading
- `my.zshenv`: User environment variables (symlinked to `~/.zshenv`)
- `env.zsh`: Core environment setup, ZDOTDIR, PATH
- `zsh-aliases`: All aliases (200+ lines)
- `zsh-exports`: Environment variable exports
- `zsh-functions`: Custom shell functions
- `zsh-optionrc`: Zsh options (interactive shell behavior)
- `zsh-complist`: Completion system configuration
- `zsh-prompt`: Prompt initialization

## Important Design Patterns

### Modular Loading
Files are loaded via `zsh_add_file` which:
- Checks file existence before sourcing
- Logs success/failure to `plugin-manager.zlog`
- Provides clear error messages with full paths

Never directly `source` files in `.zshrc` - use `zsh_add_file` for consistency.

### PATH Management
The `export_path` function (from `lib/pathtools.zsh`) intelligently adds directories to PATH:
- Prevents duplicates
- Logs all additions to `pathlog.zlog`
- Skips non-existent directories

Always use `export_path` instead of manually modifying `$PATH`.

### Logging System
Three-tier logging via `zshlog` utility:
- `--log`: Standard informational messages (green)
- `--warn`: Warnings (yellow)
- `--error`: Errors (red)

Format: `zshlog -f "logfile.zlog" --log "message"`

### Git Submodule Workflow
This repo is designed to live as a submodule in `~/.config/`. Common operations:
```bash
# Update this submodule
cd ~/.config/zsh
git add . && git commit -m "Update zsh config"
git push

# Update parent pointer
cd ~/.config
git add zsh
git commit -m "Update zsh submodule"
git push

# Combined sync (uses git-utils)
gsync "Sync zsh and parent"
```

### Asynchronous Operations
Git configuration loading in `.zshrc` runs asynchronously:
```zsh
{
    # git config operations
} > >(tee -a "$ZLOGDIR/boot_async_git.zlog") 2>&1 &!
```

This prevents blocking the shell startup on slow Git operations.

## Environment Variables

### Required
- `ZDOTDIR`: `~/.config/zsh` (set in `~/.zshenv`)
- `GITHUB_USER`: Your GitHub username (for git-utils)

### Optional but Important
- `GIT_PROVIDER`: "github" (default) or "gitlab"
- `GITLAB_USER`: Your GitLab username (auto-detected if using glab)
- `BREWDOTS`: Homebrew config directory (default: `~/.config/brew`)
- `ZUTILS`: Utils directory (default: `$ZDOTDIR/utils`)
- `BRUTILS`: Brew utils directory
- `ZLOGDIR`: Log directory (default: `$ZDOTDIR/logs`)

### Debug Flags
- `ZSH_BOOT_DEBUG`: Enable boot logging (true/false)
- `ZSHF_VERBOSE`: Function verbosity (true/false)
- `ZSHENV_DEBUG`: Environment debug mode (true/false)
- `GIT_UTILS_DEBUG`: Git utilities debug mode (true/false)

## Dependencies

### Required
- Zsh ≥ 5.8
- Git ≥ 2.30

### Strongly Recommended
- `gh` or `glab`: For Git utilities repo creation
- `fzf`: Fuzzy finder integration
- `zoxide`: Smarter directory navigation

### Optional
- `git-crypt`: File encryption
- `bat`: Better cat with syntax highlighting
- `eza`: Modern ls replacement
- `mise`: Runtime version manager

Install via Homebrew:
```bash
brew install zsh git gh fzf zoxide git-crypt bat eza mise
```

## Common Issues & Solutions

### "GITHUB_USER not set"
```bash
# Add to my.zshenv
export GITHUB_USER="your-username"
```

### ".env not found" (Brew)
```bash
brew shellenv > ~/.config/brew/.env
```

### Completions Not Working
```bash
rm -f ~/.config/zsh/.zcompdump*
compinit -i
```

### Slow Startup
```bash
# Profile to find bottleneck
zsh -i -c exit

# Check zprof output
cat ~/.config/zsh/logs/zprof.log
```

### Git Functions Not Found
```bash
# Verify PATH includes git-utils
echo $PATH | grep git-utils

# Reload shell
exec zsh
```

### Plugin Update Fails
```bash
# Manual update
cd ~/.config/zsh/plugins/<plugin-name>
git pull

# Check logs
cat ~/.config/zsh/logs/plugin-manager.zlog
```

## File Locations

### User-Facing Config
- Main config: `~/.config/zsh/.zshrc`
- Environment vars: `~/.config/zsh/my.zshenv` (symlinked from `~/.zshenv`)
- Aliases: `~/.config/zsh/zsh-aliases`
- Exports: `~/.config/zsh/zsh-exports`

### Logs (gitignored)
- Boot logs: `~/.config/zsh/logs/boot.zlog`
- Plugin logs: `~/.config/zsh/logs/plugin-manager.zlog`
- PATH logs: `~/.config/zsh/logs/pathlog.zlog`
- Performance: `~/.config/zsh/logs/zprof.log`

### Generated Files (gitignored)
- Completion cache: `~/.config/zsh/.zcompdump`
- History: `~/.config/zsh/.zsh_history`
- Sessions: `~/.config/zsh/.zsh_sessions/`
- Plugins: `~/.config/zsh/plugins/`

## Security Notes

### Secrets Management
- Git-utils includes secret scanning via `gsecrets`
- Auto-detects common patterns: API keys, tokens, credentials, private keys
- Pre-commit hooks available via `gshook`
- git-crypt integration for encryption: `gencrypt_setup`

### Git-Crypt Patterns
Automatically encrypts (when setup):
- `*.env`
- `*.key`
- `*.pem`
- `*secret*`
- `*credential*`
- `*password*`

Configuration files:
- `.gitcrypt`: Custom encryption patterns
- `.gitattributes`: git-crypt rules (auto-generated)

## Version Control

### Repository Structure
```
~/.config/zsh/          # This repository (submodule)
├── .git/               # Git repository
├── git-utils/          # Submodule: Git utilities
└── prompt/             # Submodule: Prompt system
```

### Exclusions
- `.gsubignore`: Controls what `gsub-all` ignores when batch-adding submodules
- `.gitignore`: Standard Git exclusions (plugins/, logs/, .zcompdump, etc.)

### Syncing Workflow
```bash
# Check status
gsync-status

# Sync current repo + parent
gsync "Update message"

# Sync all submodules recursively
gsync-all "Update everything"

# Pull latest
gsync-pull
```

## Platform-Specific Behavior

### Homebrew Detection
Auto-detects Homebrew location:
- Apple Silicon: `/opt/homebrew`
- Intel Mac: `/usr/local`

Brew environment cached in `$BREWDOTS/.env` for performance.

### XDG Base Directory
Follows XDG specification:
- `XDG_CONFIG_HOME`: `~/.config`
- `XDG_DATA_HOME`: `~/.local/share`
- `XDG_STATE_HOME`: `~/.local/state`
- `XDG_CACHE_HOME`: `~/.cache`

All directories auto-created on boot if missing.
