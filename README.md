# 🐚 Zsh Configuration

Modular, fast, and portable Zsh setup with custom Git workflow utilities, plugin management, and an intelligent prompt system.

## 🎯 Philosophy

- **Modular** - Each feature in its own file
- **Portable** - Works across macOS, Linux, BSD
- **Fast** - Lazy loading, PATH-based plugin system
- **Git-Centric** - Custom workflow for dotfiles + submodules
- **Self-Contained** - Lives in `~/.config/zsh` (ZDOTDIR)

## 🚀 Quick Start

### Installation

```bash
# Clone (or part of parent .config repo)
cd ~/.config/zsh

# Create essential symlinks
ln -sf ~/.config/zsh/my.zshenv ~/.zshenv

# Reload shell
exec zsh
```

### First-Time Setup

The setup auto-generates completion cache and loads all modules on first run.

## 📁 Structure

```
zsh/
├── .zshrc                    # Main config entry point (loaded via ZDOTDIR)
├── .zshrc.local              # Machine-specific overrides (gitignored, sourced last)
├── my.zshenv                 # Environment variables (symlinked to ~/.zshenv)
├── env.zsh                   # Core environment: PATH, brew shellenv, history, editor
├── env/                      # Modular env file loader (phase-ordered)
│   ├── 010-windows.zsh      # WSL paths (harmless no-op on macOS/Linux)
│   ├── 020-workspace.zsh    # Shared workspace dirs
│   ├── 030-path.zsh         # PATH additions (cargo, local, WSL)
│   ├── 040-livekit.zsh      # LiveKit config
│   └── 999-alias.zsh        # Convenience aliases
├── completions/              # Custom completion scripts
├── git-utils/                # Custom Git workflow functions (submodule)
│   ├── git-utils.zsh        # Main implementation
│   └── README.md            # Git utilities documentation
├── lib/                      # Core library functions
│   ├── plugin_manager.zsh   # Custom plugin loader
│   ├── zsh-init.zsh         # General init (aliases, exports, functions)
│   ├── zsh-fuzzy.zsh        # fzf + zoxide integration
│   ├── keybinds.zsh         # Key bindings
│   └── init-profiler.zsh    # Boot profiling
├── plugins/                  # Zsh plugins (gitignored, auto-loaded)
│   ├── zsh-autosuggestions/
│   ├── zsh-syntax-highlighting/
│   └── ...
├── prompt/                   # Prompt system (submodule)
├── utils/                    # Utility scripts
│   ├── zsh-bootlog-handler  # Boot logging framework
│   ├── history-toggle       # Shared/private history mode
│   └── zshlog               # General logging utility
└── logs/                     # Shell logs (gitignored)
```

## ✨ Key Features

### 1. 🔧 Modular Loading System

The startup follows ZDOTDIR bootstrap pattern. On macOS, the full chain is:

```
Phase 0: /etc/zshenv (system-wide, custom — sets HOMEBREW_PREFIX, path_helper)
Phase 1: ~/.zshenv → my.zshenv    # ZDOTDIR, XDG dirs, locale
Phase 2: /etc/zprofile            # macOS path_helper (reads /etc/paths.d/*)
Phase 3: ~/.zprofile → lib/.zprofile  # brew shellenv (login shells only)
Phase 4: /etc/zshrc               # macOS system defaults
Phase 5: ~/.zshrc (via ZDOTDIR)   # Main config — 12-phase bootstrap:
  ├── env.zsh                     # PATH reset, brew shellenv, history, editor
  ├── env/010-windows.zsh..999    # Modular env files (WSL, workspace, PATH, aliases)
  ├── zsh-optionrc                # Zsh options
  ├── lib/keybinds.zsh            # Key bindings
  ├── lib/plugin_manager.zsh      # Plugin loader (zsh-autosuggestions, etc.)
  ├── lib/zsh-init.zsh            # Aliases, exports, functions, completions
  ├── lib/zsh-fuzzy.zsh           # fzf + zoxide
  ├── completions.zsh             # Completion system
  ├── utils/history-toggle        # Shared/private history mode
  ├── .zshrc.local                # Machine-specific overrides (gitignored)
  └── completions/openclaw.zsh    # OpenClaw completions
```

**Key insight**: `env.zsh` resets PATH to a known base (line 23), then builds it up
layer by layer. This prevents PATH duplication from accumulated parent-process
environment — each fresh shell gets a clean, predictable PATH regardless of
what the parent shell had set.

To trace the actual loading sequence on your machine:
```zsh
zsh -il -x -c 'echo done' 2>&1 | grep -E "\.(zshrc|zshenv|zprofile)" | head -10
```

### 2. 🎨 Git-Aware Prompt

Minimal, fast prompt with:
- ✓/✗ Clean/dirty status
- ↑/↓ Ahead/behind indicators
- 🔀 Merge/rebase detection
- Virtual environment display
- Root user warnings
- Current time

See: [`prompt/README.md`](./prompt/README.md)

### 3. 🧰 Custom Git Utilities

Powerful workflow commands for managing dotfiles as Git repos + submodules:

| Command | Purpose |
|---------|---------|
| `grepo [msg] [name]` | Initialize & push new repo to GitHub |
| `gsub <dir> [msg] [name]` | Add directory as submodule |
| `gunsub <dir>` | Remove submodule completely |
| `gsync` | Sync submodule + parent repo |
| `gsub-all [-L N] <msg>` | Batch-add all folders as submodules |
| `gencrypt_setup` | Setup git-crypt encryption |
| `gsecrets` | Scan for exposed secrets |

See: [`git-utils/README.md`](./git-utils/README.md)

### 4. 🔌 Plugin System

Custom plugin manager with lazy loading:

```zsh
# In .zshrc
zsh_add_plugin "zsh-users/zsh-autosuggestions"
zsh_add_plugin "zsh-users/zsh-syntax-highlighting"
```

Plugins auto-clone to `plugins/` on first load.

### 5. ⚡ Performance

- **Fast startup** - Lazy loading, minimal PATH manipulation
- **Completion caching** - `.zcompdump` for instant completions
- **PATH-based loading** - Functions loaded on-demand from PATH

## 🔧 Configuration

### Environment Variables

Set in `my.zshenv`:

```zsh
export ZDOTDIR="$HOME/.config/zsh"
export GITHUB_USER="yourusername"
export GIT_PROVIDER="github"  # or "gitlab"
export EDITOR="nvim"
```

### Aliases & Functions

Custom aliases live in modular files:
- Zsh-specific aliases in `.zshrc`
- Shell-agnostic aliases could go in separate files

### Homebrew Integration

Auto-detects Homebrew location (Intel/Apple Silicon):

```zsh
# Automatically configured in env.zsh
eval "$(/opt/homebrew/bin/brew shellenv)"  # Apple Silicon
# or
eval "$(/usr/local/bin/brew shellenv)"      # Intel
```

## 🔐 Security Features

### Git-Crypt Integration

Auto-detects sensitive files and offers encryption:

```bash
# Automatic during grepo/gsub
gencrypt_setup ~/.config/secrets

# Manual scanning
gsecrets
```

### Pre-Commit Hooks

Secret scanning hooks auto-installed with encryption setup.

## 🧪 Testing

Git utilities include comprehensive test suites:

```bash
# Test automatic conflict resolution
~/.config/docs/zsh/git/TEST.SUITE.06.autoConflictResolution.zsh
```

## 📦 Dependencies

### Required
- **zsh** ≥ 5.8
- **git** ≥ 2.30

### Recommended
- **gh** or **glab** - For repo creation (Git utilities)
- **git-crypt** - For sensitive file encryption
- **fzf** - Fuzzy finder integration
- **zoxide** - Smarter directory navigation

Install via Homebrew:
```bash
brew install zsh git gh git-crypt fzf zoxide
```

## 🔄 Sync Across Machines

This repo is designed as a **Git submodule** in the parent `.config` repo:

```bash
# On Machine A: Update
cd ~/.config/zsh
git add . && git commit -m "Update zsh config"
git push

# On Machine B: Pull
cd ~/.config/zsh
git pull
```

Or use the custom sync commands:
```bash
gsubmod "Update zsh config"      # Update this submodule
gparent "Update config pointer"  # Update parent repo
gsync "Sync all"                 # Both at once
```

## 🛠️ Maintenance

### Regenerate Completions
```bash
rm -f ~/.config/zsh/.zcompdump*
zsh -i -c exit
```

### Update Plugins
```bash
cd ~/.config/zsh/plugins
for plugin in */; do
    (cd "$plugin" && git pull)
done
```

### Clean Logs
```bash
rm -rf ~/.config/zsh/logs/*
```

## 📚 Related Documentation

- **Git Utilities:** [`git-utils/README.md`](./git-utils/README.md)
- **Prompt System:** [`prompt/README.md`](./prompt/README.md)
- **Parent Config:** `~/.config/` (main dotfiles repo)
- **Setup Guide:** `~/.config/docs/SETUP.md`

## 🌍 Platform Support

- ✅ **macOS** - Full support (primary development platform)
- ✅ **Linux** - Full support (Ubuntu, Arch, etc.)
- ✅ **BSD** - Basic support (may need adjustments)
- ❌ **Windows** - Use WSL2

## 🔗 Submodules

- **prompt/** - Git-aware prompt system
- **git-utils/** - Custom Git workflow utilities

## 🚨 Troubleshooting

### Shell Startup Slow?
```bash
# Profile startup time
zsh -i -c exit  # Time this command
```

Check for:
- Large completion files
- Slow plugins (disable one by one)
- Network calls during startup

### Completions Not Working?
```bash
# Rebuild completion cache
rm ~/.config/zsh/.zcompdump*
compinit
```

### `~/.zshrc` Not Found at Home?

This is **normal** when ZDOTDIR is in use. The real config lives at
`$ZDOTDIR/.zshrc` (`~/.config/zsh/.zshrc`). A stale `~/.zshrc` at `$HOME` is
never read — zsh reads from `$ZDOTDIR/.zshrc` instead.

Confirm your ZDOTDIR is set correctly:
```zsh
echo $ZDOTDIR        # Should show ~/.config/zsh
```

Test that the right file loads:
```zsh
zsh -i -c 'echo $ZUTILS'   # Should show ~/.config/zsh/utils
```

### Git Functions Not Found?
```bash
# Check PATH includes git-utils
echo $PATH | grep git-utils

# Reload shell
exec zsh
```

## 💡 Tips & Tricks

### Custom Functions
Add personal functions to `.zshrc` or create `custom/` directory.

### Override Defaults
Create `.zshrc.local` for machine-specific config (gitignored).

### Backup Before Changes
```bash
cp .zshrc .zshrc.backup
```

## 📝 License

Part of personal dotfiles configuration. Use freely, modify as needed.

---

**Last Updated:** 2026-06-09
**Maintained by:** [@smnuman](https://github.com/smnuman)
