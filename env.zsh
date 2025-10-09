#!/usr/bin/env bash

# sourced from ~/.zshenv
# --------- HARDCODED default files ---------
export ZLOGFILE="zsh.zlog"                      # Log file for this .zshrc
export BREWLOGFILE="brew.zlog"                  # Log file for brew activities

export ZUTILS="$HOME/.config/zsh/utils"
export BRUTILS="$HOME/.config/brew/utils"

export ZSHF_VERBOSE="false"                      # zsh-functions verbosity

. $ZUTILS/zsh-utils.zsh

[[ "$ZSHENV_DEBUG" == "true" ]] && zshenv_report
