#!/usr/bin/env zsh

# --- Default logging location and file ---
[[ -f "$HOME/.config/zsh/utils/zsh-utils.zsh" ]] && . "$HOME/.config/zsh/utils/zsh-utils.zsh" || echo ".zshrc: ZSH Utils not found (check: $HOME/.config/zsh/utils/zsh-util.zsh)"

[[ ! -f ~/.gitconfig ]] && ln -s ~/.config/git/gitconfig ~/.gitconfig

# === Enforce SSH for GitHub remotes if not already set ===
if ! git config --global --get url."git@github.com:".insteadOf >/dev/null; then
    git config --global url."git@github.com:".insteadOf "https://github.com/"
fi

export GIT_PROVIDER="github"    # or "gitlab" (default: github)

if [[ -z "$GITHUB_USER" ]]; then
  email=$(git config user.email 2>/dev/null)
  [[ -n "$email" ]] && { export GITHUB_USER="${email%@*}" } || \
    echo ".zshrc: GITHUB_USER not set and could not be inferred from git config"
fi

if [[ -z "$GITLAB_USER" ]]; then
  username=$(glab api user | jq -r '.username' 2>/dev/null)
  [[ -n "$username" ]] && { export GITLAB_USER="${username}" } || \
    echo ".zshrc: GITLAB_USER not set and could not be inferred from git config"
fi

mkdir -p "$BREWDOTS" "$BRUTILS" "$ZUTILS"    # "$ZDOTDIR"

[[ -f "$ZUTILS/zsh-utils.zsh" ]] &&  source "$ZUTILS/zsh-utils.zsh" || \
    echo ".zshrc: ZSH Utils not found (check: $ZUTILS/zsh-util.zsh)"

[[ -f "$ZDOTDIR/lib/plugin_manager.zsh" ]] && {
    source "$ZDOTDIR/lib/plugin_manager.zsh"
    zsh_auto_update_plugins
} || \
    echo ".zshrc: ZSH Plugin manager not found (check: $ZDOTDIR/lib)"

# Source interactive shell behaviour (only works because we're interactive here)
[[ -o interactive ]] && . "$ZDOTDIR/zsh-optionrc"

# Instead of running this ...
# eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"
# ... run the following:
if [[ ! -f "$HOME/.config/zsh/.brew_env" ]]; then
    $HOMEBREW_PREFIX/bin/brew shellenv > "$HOME/.config/zsh/.brew_env"
fi
source "$HOME/.config/zsh/.brew_env"

[[ -f $ZDOTDIR/lib/keybinds.zsh ]] && . "$ZDOTDIR/lib/keybinds.zsh"
[[ -f $ZDOTDIR/lib/plugin_manager.zsh ]] && . $ZDOTDIR/lib/plugin_manager.zsh

echo -e "\n\t=== === === B O O T I N G === === ===\n"

# Enable hook & colors
autoload -Uz add-zsh-hook
autoload -Uz colors && colors

autoload -Uz compinit && compinit
zmodload zsh/complist

# Add zsh plugins with my plugin manager
if [[ -f ~/.config/zsh/env.zsh ]]; then
    # zsh_add_file "$ZDOTDIR/utils/zsh-utils.zsh"  # - General zsh utilities like: zshlog(), zsh_report(), etc.
	# Normal z-files to source
	zsh_add_file "lib/pathtools.zsh"        # - Use EXPORT intelligently without bloating PATH environment var: creates logfile in ~/.config/zsh/logs/pathlog.zlog
	zsh_add_file "zsh-exports"              # - All export variables
    zsh_add_file "zsh-complist"             # - zsh/complist plugin for better completion
	# zsh_add_file "zsh-vim-mode"             # - Vim mode, etc.
	zsh_add_file "zsh-aliases"              # - Keep all your aliases in one place
    zsh_add_file "zsh-prompt"               # - This file sources .prompt.zsh and sets up the prompt
    zsh_add_file "zsh-functions"            # Functions like: - brew_log_summary(), - clear_brew_logs() etc.
    zsh_add_file "git-utils/git-utils.zsh"  # - Git utilities like: - gsync, - grepo, - gsub etc.

	# Load z-plugins
	zsh_add_plugin zsh-users/zsh-autosuggestions
	zsh_add_plugin zsh-users/zsh-syntax-highlighting
	zsh_add_plugin zsh-users/zsh-history-substring-search
    zsh_add_plugin smnuman/zsh-history-search-end-match
    zsh_add_plugin supercrabtree/k

	# Load z-completions
    zsh_add_completion gutils
	zsh_add_completion zsh-users/zsh-completions true
else
    echo "\n\tNo \" ~/.config/zsh/env.zsh\" found. Please create it for custom configurations."
    echo "\tNo file, plugin or completions is sourced.!! \n"
fi


# Completion sorting and grouping
zstyle ':completion:*' sort true
zstyle ':completion:*' list-suffixes true
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*:files' ignored-patterns '*~' '*.o' '*.pyc'
zstyle ':completion:*' file-patterns '*(-/):directories' '*(N)'
zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$ZDOTDIR/.zcompcache"
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' expand 'yes'

# =====================================================
# --- Custom functions and keybindings ---
# autoload -U up-line-or-beginning-search
# autoload -U down-line-or-beginning-search
# zle -N up-line-or-beginning-search
# zle -N down-line-or-beginning-search
# bindkey '^P' up-line-or-beginning-search    # Ctrl+P for up
# bindkey '^N' down-line-or-beginning-search  # Ctrl+N for down

# --- Initialise fzf and zoxide ---
if command -v fzf >/dev/null 2>&1; then
  # Source shell completions and key bindings
  if [[ -f ~/.fzf/shell/completion.zsh ]]; then
    source ~/.fzf/shell/completion.zsh
    source ~/.fzf/shell/key-bindings.zsh
  elif command -v brew >/dev/null 2>&1 && [[ -f "$(brew --prefix)/opt/fzf/shell/completion.zsh" ]]; then
    source "$(brew --prefix)/opt/fzf/shell/completion.zsh"
    source "$(brew --prefix)/opt/fzf/shell/key-bindings.zsh"
  fi
  # Initialise fzf for zsh
  eval "$(fzf --zsh)"
fi

# Initialise zoxide
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
# =====================================================
