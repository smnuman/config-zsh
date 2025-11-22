#!/usr/bin/env zsh
zmodload zsh/zprof
# -------------------------- Bootlog alert ------------------------
# # === source User env Configurations: env.zsh ===
[[ -f "$ZDOTDIR/env.zsh" ]] && source "$ZDOTDIR/env.zsh";

PROMPT_SHOWN="false"
export PROMPT_SHOWN
precmd() { PROMPT_SHOWN="true" }

{
    # echo "ZDOTDIR is set to: ${ZDOTDIR/#$HOME/~}"
    if typeset -f zsh_bootlog >/dev/null 2>&1; then zsh_bootlog "Phase 3: Configuring git settings in .zshrc"; else echo "${(%):-%N}: zsh_bootlog not found!!!"; fi
    [[ ! -f ~/.gitconfig ]] && ln -s ~/.config/git/gitconfig ~/.gitconfig 2>/dev/null
    [[ -f "$ZDOTDIR/lib/zsh-initgit.zsh" ]] && . "$ZDOTDIR/lib/zsh-initgit.zsh" 2>/dev/null || echo ".zshrc: 'zsh-initgit.zsh' file not found (check: $ZDOTDIR/lib/zsh-initgit.zsh)"
} > >(tee -a "$ZLOGDIR/boot_async_git.zlog") 2>&1 &!

[[ -f "$ZDOTDIR/git-utils/git_users.zsh" ]] && . "$ZDOTDIR/git-utils/git_users.zsh"

# Source interactive shell behaviour (only works because we're interactive here)
zsh_bootlog "Phase 4: Loading zsh options" && . "$ZDOTDIR/zsh-optionrc"

# Controlled Brew environment sourcing
zsh_bootlog "Phase 5: Loading brew environment"
[[ -f "$BREWDOTS/.env" ]] && . "$BREWDOTS/.env" || print -P  ".zshrc says: brew '.env' not found. Run '%F{yellow}brew shellenv > $BREWDOTS/.env%f'"

zsh_bootlog "Phase 6: Loading zsh options"
[[ -f "$ZDOTDIR/lib/keybinds.zsh" ]] && . "$ZDOTDIR/lib/keybinds.zsh"

zsh_bootlog "Phase 7: zsh plugin manager loading..."
[[ -f "$ZDOTDIR/lib/plugin_manager.zsh" ]] && . $ZDOTDIR/lib/plugin_manager.zsh || echo ".zshrc says: ZSH Plugin manager not found (check: $ZDOTDIR/lib)"

echo -e "\n\t=== === === B O O T I N G === === ===\n"

# Enable hook & colors
autoload -Uz add-zsh-hook
autoload -Uz colors && colors

autoload -Uz compinit && compinit -C
zmodload zsh/complist

zsh_bootlog "Phase 8: Adding zsh plugins"
[[ -f "$ZDOTDIR/lib/zsh-init.zsh" ]] && . "$ZDOTDIR/lib/zsh-init.zsh" || echo ".zshrc says: zsh-init.zsh file not found (check: $ZDOTDIR/lib/)"

zsh_bootlog "Phase 9: Adding zsh fuzzy"
[[ -f "$ZDOTDIR/lib/zsh-fuzzy.zsh" ]] && . "$ZDOTDIR/lib/zsh-fuzzy.zsh" || echo ".zshrc says: zsh-fuzzy.zsh file not found (check: $ZDOTDIR/lib/)"

[[ -f "$ZUTILS/history-toggle" ]] && . "$ZUTILS/history-toggle" 2>/dev/null || echo ".zshrc says: 'history-toggle' utility not found (check: ${ZUTILS/$HOME/~}/history-toggle)"

zsh_bootlog "Phase 10: .zshrc complete."
zprof > $ZLOGDIR/zprof.log
