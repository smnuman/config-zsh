#!/usr/bin/env zsh
# ~/.config/zsh/env.zsh         # sourced from ~/.zshenv
# ===============================================================
#                  NOMAD Zsh Environment Setup
# ===============================================================
# Sets up XDG directories, log files, utils, and sources brew env
# ===============================================================

for dir in "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"; do
  [[ -d "$dir" ]] || mkdir -p "$dir"
done

# --------- HARDCODED default env files setup ---------
export ZLOGFILE="zsh.zlog"                      # Log file for this .zshrc
export BREWLOGFILE="brew.zlog"                  # Log file for brew activities

export ZUTILS="$HOME/.config/zsh/utils"
export BRUTILS="$HOME/.config/brew/utils"

export ZSHF_VERBOSE="false"                      # zsh-functions verbosity

[[ "$ZSHENV_DEBUG" == "true" ]] && zshenv_report

# Load Brew environment
. "$BREWDOTS/.env"
