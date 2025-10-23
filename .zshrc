#!/usr/bin/env zsh
[[ ! -f ~/.gitconfig ]] && ln -s ~/.config/git/gitconfig ~/.gitconfig 2>/dev/null
[[ -f "$ZDOTDIR/lib/zsh-initgit.zsh" ]] && . "$ZDOTDIR/lib/zsh-initgit.zsh" || echo ".zshrc: 'zsh-initgit.zsh' file not found (check: $ZDOTDIR/lib/zsh-initgit.zsh)"

# Source interactive shell behaviour (only works because we're interactive here)
[[ -o interactive ]] && . "$ZDOTDIR/zsh-optionrc"

# Controlled Brew environment sourcing
[[ -f "$BREWDOTS/.env" ]] && . "$BREWDOTS/.env" || print -P  ".zshrc says: '.env' not found. Run '%F{yellow}brew shellenv > $BREWDOTS/.env%f'"

[[ -f "$ZDOTDIR/lib/keybinds.zsh" ]] && . "$ZDOTDIR/lib/keybinds.zsh"
[[ -f "$ZDOTDIR/lib/plugin_manager.zsh" ]] && . $ZDOTDIR/lib/plugin_manager.zsh || echo ".zshrc: ZSH Plugin manager not found (check: $ZDOTDIR/lib)"

echo -e "\n\t=== === === B O O T I N G === === ===\n"

[[ -f "$ZUTILS/history-toggle" ]] && . "$ZUTILS/history-toggle" 2>/dev/null || echo ".zshrc: 'history-toggle' utility not found (check: ${ZUTILS/$HOME/~}/history-toggle)"

# Enable hook & colors
autoload -Uz add-zsh-hook
autoload -Uz colors && colors

autoload -Uz compinit && compinit -C
zmodload zsh/complist

[[ -f "$ZDOTDIR/lib/zsh-init.zsh" ]] && . "$ZDOTDIR/lib/zsh-init.zsh" || echo ".zshrc: zsh-init.zsh file not found (check: $ZDOTDIR/lib/zsh-init.zsh)"
[[ -f "$ZDOTDIR/lib/zsh-fuzzy.zsh" ]] && . "$ZDOTDIR/lib/zsh-fuzzy.zsh" || echo ".zshrc: zsh-fuzzy.zsh file not found (check: $ZDOTDIR/lib/zsh-fuzzy.zsh)"
