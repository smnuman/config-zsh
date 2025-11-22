#!/usr/bin/env zsh
# ~/.config/zsh/env.zsh
# ===============================================================
#             *** CONSISTENT NOMAD Zsh ENVIRONMENT ***
# ===============================================================
# Guarantees predictable boot-variable state, and ensures that
# zsh-bootlog-handler is sourced only AFTER all ZSHF_* vars are set.
# ===============================================================
# Sets up XDG directories, log files, utils, and sources brew env
# ===============================================================

export ZSHENV_DEBUG="false"                     # env debug mode
export ZSHF_VERBOSE="false"                      # function verbosity
export ZSH_DEBUG_BOOT="true"                   # boot debug logs
export ZSH_PERF_MODE="${ZSH_PERF_MODE:-true}"    # performance mode for faster boots

export GIT_PROVIDER="gitlab"                    # "github" or "gitlab" (default: github)

[[ -z "$ZUTILS" ]] && ZUTILS="$HOME/.config/zsh/utils"
export ZUTILS

# prepend utils (so bootlog-handler becomes discoverable)
export PATH="$ZUTILS:$PATH"

[[ "$ZSH_DEBUG_BOOT" == "true" ]] && print -P "%F{yellow}⚙️  ZSH Boot Debug Mode Active — logs at $ZLOGDIR/boot.zlog%f"

if [[ -f "$ZUTILS/zsh-bootlog-handler" ]]; then
    source "$ZUTILS/zsh-bootlog-handler"
    [[ "$ZSH_DEBUG_BOOT" == "true" ]] && [[ "$ZSHF_VERBOSE" == "true" ]] && print -- "<env.zsh[$LINENO]>: bootlog-handler successfully sourced from ${(q)ZUTILS}/zsh-bootlog-handler"
else
    print -- "<env.zsh[$LINENO]>: bootlog-handler not found in ${(q)ZUTILS}" >&2
fi

# Phase 1 :done in ~/.zshenv. Following code requires that bootlog-handler be loaded first
zsh_bootlog "Phase 1: ~/.zshenv (symlink to ~/.config/zsh/my.zshenv) complete.  env.zsh entered"

export PATH="$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

for dir in "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"; do
  [[ -d "$dir" ]] || mkdir -p "$dir"
done

[[ "$ZSHENV_DEBUG" == "true" ]] && "${ZUTILS}"/zshenv_report

[[ -f "$BREWDOTS/.env" ]] && source "$BREWDOTS/.env"

zsh_bootlog "Phase 2: env.zsh completed"


# *****************************************************


# #!/usr/bin/env zsh
# # ~/.config/zsh/env.zsh         # sourced from ~/.zshenv
# # ===============================================================
# #                  NOMAD Zsh Environment Setup
# # ===============================================================
# # Sets up XDG directories, log files, utils, and sources brew env
# # ===============================================================


# export ZSHF_VERBOSE="false"                     # zsh-functions verbosity
# export ZSHENV_DEBUG="false"                     # Set env debug to "true" to enable debug env info
# export ZSH_DEBUG_BOOT="false"                   # Set boot debug to "true" to get debug info during shell boot

# [[ -z "$ZUTILS" ]] && ZUTILS="$HOME/.config/zsh/utils"
# export ZUTILS
# export PATH="$ZUTILS:$PATH"

# # # --- Bootlog handler early load (before sourcing env.zsh) ---
# [[ -f $ZUTILS/zsh-bootlog-handler ]] && source $ZUTILS/zsh-bootlog-handler 2>/dev/null  && echo "\n\tbootlog-handler successfully sourced!\n" || echo "<- ${${(%):-%N}:t}[$LINENO] ->: 'zsh-bootlog-handler' utility not found (check: ${ZUTILS/#$HOME/~}/zsh-bootlog-handler)";

# # === Secure Default PATH ===
# export PATH="$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# # ------------------------------ Boot Debug Logger ------------------------------
# # ~/.zshenv
# # [[ -f "$HOME/.config/zsh/utils/zsh-bootlog-handler" ]] && source "$HOME/.config/zsh/utils/zsh-bootlog-handler" # 2>/dev/null || echo "<env.zsh[$LINENO]>: 'zsh-bootlog-handler' utility not found (check: ${ZUTILS/#$HOME/~}/zsh-bootlog-handler)"
# # [[ "$ZSH_DEBUG_BOOT" == "true" ]] &&
# touch "$ZLOGDIR/boot.zlog"
# # && { source "$ZUTILS/zsh-bootlog-handler" 2>/dev/null || echo "<- ${${(%):-%N}:t}[$LINENO] ->: 'zsh-bootlog-handler' utility not found (check: ${ZUTILS/#$HOME/~}/zsh-bootlog-handler)" ; }

# zsh_bootlog "Phase 1: ~/.zshenv (symlink to ~/.config/zsh/my.zshenv) complete. " # || echo "<- ${${(%):-%N}:t}[$LINENO] ->: zsh_bootlog not found!!!"

# # --------- XDG Base Directory Check & Setup ---------
# for dir in "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"; do
#   [[ -d "$dir" ]] || mkdir -p "$dir"
# done

# [[ "$ZSHENV_DEBUG" == "true" ]] && "${ZUTILS}"/zshenv_report

# # Load Brew environment
# [[ -f "$BREWDOTS/.env" ]] && source "$BREWDOTS/.env"

# zsh_bootlog "Phase 2: ${ZDOTDIR/#$HOME/~}/env.zsh completed"
