# Add zsh plugins with my plugin manager
zsh_add_file "lib/completions"          # - Custom completions
zsh_add_file "lib/keybinds.zsh"
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
# zsh_add_plugin eza-community/eza-themes   # NOT TO BE SOURCED
zsh_add_plugin Aloxaf/fzf-tab
zsh_add_plugin smnuman/zsh-history-search-end-match
zsh_add_plugin supercrabtree/k

# Load zsh-completions (now in background)
zsh_add_completion gutils
zsh_add_completion zsh-users/zsh-completions true

# Apply background completions after shell fully loaded (suppress job control)
{ sleep 1; apply_background_completions } &!

# ===================
