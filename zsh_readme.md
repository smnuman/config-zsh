# 🔀 Zsh Configuration Overview

This directory contains a **modular, portable, and minimal Zsh setup** designed for the NOMAD workflow.\
Each component lives in its own file to keep startup predictable, debuggable, and easy to extend.

---

## ⚙️ Structure Overview

```
~/.config/zsh/
├── .zshrc                  # Main entrypoint – orchestrates all configs
├── env.zsh                 # Core environment variables & path exports
├── lib/
│   ├── zsh-init.zsh        # Plugin manager & completions
│   ├── zsh-initgit.zsh     # GitHub/GitLab logic & environment
│   ├── zsh-fuzzy.zsh       # fzf and zoxide initialization
│   ├── keybinds.zsh        # Keybinding setup
│   └── plugin_manager.zsh  # Custom plugin loader
└── logs/                   # Optional logs (e.g., PATH, zshlog)
```

---

## 🥉 Boot Sequence

1. \`\` sets `$ZDOTDIR` → `~/.config/zsh`
2. \`\` executes:
   - Enforces symlink for `.gitconfig`
   - Loads `zsh-initgit.zsh`
   - Loads `zsh-optionrc` (interactive shell)
   - Sources Homebrew environment from `$BREWDOTS/.env`
   - Loads `keybinds.zsh` and `plugin_manager.zsh`
   - Prints a boot banner
   - Initialises completions (`compinit -C`)
   - Loads `zsh-init.zsh` (plugins, completions, aliases)
   - Loads `zsh-fuzzy.zsh` (fzf & zoxide)

---

## ⚡ Quick Commands

- **Reload shell**

  ```bash
  source ~/.config/zsh/.zshrc
  ```

- **Regenerate Brew environment**

  ```bash
  brew shellenv > ~/.config/brew/.env
  ```

- **Refresh completions**

  ```bash
  compinit -i
  ```

- **View path exports**

  ```bash
  cat ~/.config/zsh/logs/pathlog.zlog
  ```

---

## 🤠 Troubleshooting

### 🔸 `.brew_env` / `.env` not found

- Run:
  ```bash
  brew shellenv > ~/.config/brew/.env
  ```
- Ensure `$BREWDOTS` points to the correct location:
  ```bash
  echo $BREWDOTS
  ```

### 🔸 GitLab user not set

Network hiccups may delay `glab` response. The system retries up to 5 times, then falls back to:

```bash
git config user.name
```

To manually refresh:

```bash
unset GITLAB_USER
source ~/.config/zsh/.zshrc
```

### 🔸 fzf or zoxide not loading

- Confirm installation:
  ```bash
  command -v fzf zoxide
  ```
- Check paths in:
  ```
  ~/.config/zsh/lib/zsh-fuzzy.zsh
  ```

### 🔸 Completions too slow

- Use cached init:
  ```bash
  autoload -Uz compinit && compinit -C
  ```
- Or clean cache:
  ```bash
  rm -f ~/.zcompdump*
  ```

---

## 🤷️‍♂️ Design Philosophy

> “Everything modular, nothing redundant.”

- Each function is isolated in a `lib/` file.
- Only interactive shells load interactive modules.
- No silent auto-creation — every missing config reports itself clearly.
- Built for **speed, portability, and transparency.**

---

**Maintainer:** [@smnuman](https://github.com/smnuman)\
**Updated:** 17 Oct 2025
