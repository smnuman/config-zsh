#!/usr/bin/env zsh

# ---------------------------------------------------------------------
# WSL login shell enforcement
# ---------------------------------------------------------------------

if [[ -z "$ZSH_WSL_LOGIN_DONE" ]] && grep -qi microsoft /proc/version; then
    export ZSH_WSL_LOGIN_DONE=1

    if [[ "$SHLVL" -eq 1 && ! -o login ]]; then
        exec /usr/bin/zsh -l
    fi
fi

# ---------------------------------------------------------------------
# Session / machine environment
# ---------------------------------------------------------------------

setopt null_glob

for file in $HOME/.config/zsh/env/*.zsh; do
    source "$file"
done

unsetopt null_glob

source $HOME/.config/zsh/lib/identity-resolver.zsh
source $HOME/.config/zsh/lib/windows-bridge.zsh
source $ZUTILS/wsl.zsh

# Optional external env
[[ -f "$HOME/.local/share/../bin/env" ]] && source "$HOME/.local/share/../bin/env"

