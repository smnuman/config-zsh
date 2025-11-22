# ~/.zshenv  that is  simlinked from here: ~/.config/zsh/my.zshenv
# ------- the silent shell environment setup file [ won't be showing any echoes!! ] -------
# -------------------------- keep it most minimal pls -------------------------------
# This file is sourced on all invocations of the shell, including non-interactive ones.
# It should contain only environment variable definitions, and other things that should
# be set for all types of shell sessions.

# === System Locale ===
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# === Universal umask (default permissions for new files) ===
umask 022                                       # Default: 755 for dirs, 644 for files

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

export ZDOTDIR="$HOME/.config/zsh"              # === ZDOTDIR (my dotfiles home) ===
export ZLOGDIR="$HOME/.config/zsh/logs"         # === ZSH Log Directory (general logs) ===
export BREWDOTS="$HOME/.config/brew"            # === BREWDOTS (brew dotfiles) ===
export BREWLOGS="$HOME/.config/brew/logs"       # === BREWLOGDIR (brew related logs) ===

export ZUTILS="$HOME/.config/zsh/utils"         # === ZSH Utils Directory ===
export BRUTILS="$HOME/.config/brew/utils"       # === BREW Utils Directory ===

# --------- HARDCODED default env log files setup ---------
export ZLOGFILE="zsh.zlog"                      # Log file for this .zshrc
export BREWLOGFILE="brew.zlog"                  # Log file for brew activities

export GREP_NOCOLOR=$(grep --no-color "" /dev/null >/dev/null 2>&1 && echo "--no-color" || grep --color=never "" /dev/null >/dev/null 2>&1 && echo "--color=never" || echo "")

export BAT_CONFIG_DIR="$HOME/.config/bat"       # === Bat Config Directory ===

# === History Settings ===
HISTFILE="$HOME/.zsh_history"
HISTSIZE=200000
SAVEHIST=200000

export EDITOR="nvim"                            # === Editor ===
export VISUAL="code"                            # === Editor ===

setopt prompt_subst                             # === Minimal Shell Hinting ===
