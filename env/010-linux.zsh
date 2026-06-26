# ~/.config/zsh/env/010-linux.zsh

[[ "$PLATFORM" != "linux" ]] && return

# ===== Linux-specific environment =====

export OS_NAME="linux"

# Standard editor fallback
export EDITOR="nano"

# Linux VS Code fallback (common locations)
if [[ -x "$(command -v code)" ]]; then
    export VSCODE_BIN="$(command -v code)"
fi

# Useful defaults
export PAGER="less"
export BROWSER="firefox"
