#!/usr/bin/env zsh
# ~/.config/zsh/env.zsh
# ===============================================================
#             *** CONSISTENT NOMAD Zsh ENVIRONMENT ***
# ===============================================================
# Sets up XDG directories, log files, utils, and sourced before .zshrc
# Phase 1–2 of the boot sequence (Phase 0 is my.zshenv — silent)
# ===============================================================

export ZSHENV_DEBUG="false"
export ZSH_PATH_DEBUG="false"               # used in pathtools.zsh to toggle path export debug logs
export ZSHF_VERBOSE="false"
export ZSH_DEBUG_BOOT="false"
export ZSH_PROFILE="true"

export GIT_PROVIDER="github"

export ZSHLIB="${ZDOTDIR}/lib"

export ZUTILS="$HOME/.config/zsh/utils"

export PATH="$ZUTILS:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

export PATH=$HOME/.opencode/bin:$PATH   # opencode

export PATH="$DPRINT_INSTALL/bin:$PATH"

[[ "$ZSH_DEBUG_BOOT" == "true" ]] && print -P "%F{yellow}ZSH Boot Debug Active — logs at $ZLOGDIR/boot.zlog%f"

# === zsh Boot Logger ===
if [[ -f "$ZUTILS/zsh-bootlog-handler" ]]; then
    source "$ZUTILS/zsh-bootlog-handler"
fi

zsh_bootlog "Phase 1: env.zsh entered (my.zshenv complete)"

# === Init Profiler ===
source "$ZSHLIB/init-profiler.zsh" 2>/dev/null
zprof_start "TOTAL"
zprof_start ".env.zsh"

for dir in "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"; do
  [[ -d "$dir" ]] || mkdir -p "$dir"
done

# === History ===
HISTFILE="$HOME/.zsh_history"
HISTSIZE=200000
SAVEHIST=200000

# === Editor ===
export EDITOR="nvim"
export VISUAL="code"

# === Shell Options ===
setopt prompt_subst

# === Computed ===
export GREP_NOCOLOR=$(grep --no-color "" /dev/null >/dev/null 2>&1 && echo "--no-color" || grep --color=never "" /dev/null >/dev/null 2>&1 && echo "--color=never" || echo "")

[[ "$ZSHENV_DEBUG" == "true" ]] && "${ZUTILS}"/zshenv_report

zprof_end ".env.zsh"

zsh_bootlog "Phase 2: env.zsh completed"
