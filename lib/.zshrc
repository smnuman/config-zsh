#!/usr/bin/env zsh
# Set up basic history
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000

setopt HIST_SAVE_NO_DUPS    # Save history without duplicates
setopt HIST_FIND_NO_DUPS    # Do not find duplicates in history search
setopt HIST_REDUCE_BLANKS   # Reduce blanks in history
setopt INC_APPEND_HISTORY   # Append to history file incrementally
setopt SHARE_HISTORY        # Share history across all sessions
setopt PROMPT_SUBST          # Substitute in prompt

# Enable command auto-correction
setopt correct

# Move to directories without cd
setopt autocd

# if [[ ! -f ~/.config/zsh/lib/keybindings.zsh ]]; then
#     bindkey -e  # Use Emacs bindings (standard)

#     # Fix Backspace (delete char before cursor)
#     bindkey '^?' backward-delete-char     # ASCII DEL (common)
#     bindkey '^H' backward-delete-char     # Sometimes sent instead

#     # Fix Delete key (delete char under cursor — like Windows "Del")
#     bindkey '^[[3~' delete-char

#     # Restore arrow keys (just to be safe, though you already set two of them)
#     bindkey '^[[A' up-line-or-search
#     bindkey '^[[B' down-line-or-search
#     bindkey '^[[C' forward-char
#     bindkey '^[[D' backward-char

#     # Use the up and down keys to navigate the history
#     bindkey '\e[A' history-substring-search-up
#     bindkey '\e[B' history-substring-search-down
# fi

# Enable completion
autoload -Uz compinit; compinit

# Add zsh plugins wth my plugin manager
if [[ -f ~/.config/zsh/env.zsh ]]; then
	# Useful Functions
	source ~/.config/zsh/env.zsh        # important! must set first!
    source zsh-optionrc

	# Normal z-files to source
    # zsh_add_file "lib/keybinds.zsh"
	zsh_add_file "lib/pathtools.zsh"    # - Use EXPORT intelligently without bloating PATH environment var: creates logfile in ~/.config/zsh/logs/pathlog.zlog
	zsh_add_file "zsh-exports"          # - All export variables
	# zsh_add_file "zsh-vim-mode"
	zsh_add_file "zsh-aliases"          # - Keep all your aliases in one place
    zsh_add_file "zsh-prompt"           # - This file sources .prompt.zsh and sets up the prompt
    zsh_add_file "zsh-functions"        # Functions like: - brew_log_summary(), - clear_brew_logs() etc.
    zsh_add_file "zsh-git-utils"        # - Git utilities like: - gsync, - grepo, - gsub etc.

	# Load z-plugins
	zsh_add_plugin zsh-users/zsh-autosuggestions
	zsh_add_plugin zsh-users/zsh-syntax-highlighting
	zsh_add_plugin zsh-users/zsh-history-substring-search
    zsh_add_plugin smnuman/zsh-history-search-end-match
    zsh_add_plugin supercrabtree/k
	# Load z-completions
	zsh_add_completion zsh-users/zsh-completions true
fi
