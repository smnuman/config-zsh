# ~/.config/zsh/env/010-macos.zsh

[[ "$PLATFORM" != "macos" ]] && return

# ===== macOS-specific environment =====

export OS_NAME="macos"

# Homebrew (Apple Silicon default)
export BREW_PREFIX="/opt/homebrew"

# VS Code (macOS native install)
export VSCODE_BIN="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"

# Preferred editor fallback
export EDITOR="code"

# macOS-specific utilities (optional)
alias showfiles="defaults write com.apple.finder AppleShowAllFiles YES; killall Finder"
alias hidefiles="defaults write com.apple.finder AppleShowAllFiles NO; killall Finder"
