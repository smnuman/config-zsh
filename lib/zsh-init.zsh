# Add zsh plugins with my plugin manager
zsh_add_file "lib/pathtools.zsh"        # - Use EXPORT intelligently without bloating PATH environment var: creates logfile in ~/.config/zsh/logs/pathlog.zlog
zsh_add_file "zsh-exports"              # - All export variables
zsh_add_file "zsh-complist"             # - zsh/complist plugin for better completion
# zsh_add_file "zsh-vim-mode"             # - Vim mode, etc.
zsh_add_file "zsh-aliases"              # - Keep all your aliases in one place
zsh_add_file "zsh-prompt"               # - This file sources .prompt.zsh and sets up the prompt
zsh_add_file "zsh-functions"            # Functions like: - brew_log_summary(), - clear_brew_logs() etc.
zsh_add_file "git-utils/git-utils.zsh"  # - Git utilities like: - gsync, - grepo, - gsub etc.

# Load zsh-plugins
zsh_add_plugin zsh-users/zsh-autosuggestions
zsh_add_plugin zsh-users/zsh-syntax-highlighting
zsh_add_plugin zsh-users/zsh-history-substring-search
zsh_add_plugin Aloxaf/fzf-tab
zsh_add_plugin smnuman/zsh-history-search-end-match
zsh_add_plugin supercrabtree/k

# Load zsh-completions
zsh_add_completion gutils
zsh_add_completion zsh-users/zsh-completions true

# ===================

# Completion sorting and grouping
zstyle ':completion:*'              sort true
zstyle ':completion:*'              list-suffixes true
zstyle ':completion:*'              group-name ''
zstyle ':completion:*'              menu no                              # default 'select'
zstyle ':completion:*'              matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*:default'      list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:files'        ignored-patterns '*~' '*.o' '*.pyc'
zstyle ':completion:*'              file-patterns '*(-/):directories' '*(N)'
zstyle ':completion:*'              verbose yes
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*'              use-cache on
[[ -d "$ZDOTDIR/.zcompcache" ]] || mkdir -p "$ZDOTDIR/.zcompcache"
zstyle ':completion:*'              cache-path "$ZDOTDIR/.zcompcache"
zstyle ':completion:*'              expand 'yes'
zstyle ':fzf-tab:complete:cd:*'     fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*'  fzf-preview 'ls --color $realpath'
