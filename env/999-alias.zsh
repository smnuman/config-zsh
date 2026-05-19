# ===== Quick navigation =====

alias cw='cd $CLAUDE_WS'
alias pw='cd $PROJECTS_WS'

# alias bat='batcat'
alias claude-mem='bun "$HOME/.claude/plugins/marketplaces/thedotmack/plugin/scripts/worker-service.cjs"'
alias path='echo ${PATH//:/\\n}'

# shell utils
alias c='clear'
alias s='source ~/.config/zsh/.zshrc && hash -r && echo "\n\t===== new zsh sourced =====\n" || echo "\nxxxxx Failed sourcing new zsh xxxxx\n"'

# VS Code (WSL-native is best)
alias code='"$VSCODE_PATH/code" '
alias c.='"$VSCODE_PATH/code" .'
alias c-='"$VSCODE_PATH/code" '

# editors
alias v='vim '
alias e='vim '

# ai tui
alias cc='claude'
alias ccd='claude --dangerously-skip-permissions'

# Miscellaneous
alias aliasfile='$HOME/.config/zsh/env/999-alias.zsh'
alias ClawCheck='schtasks.exe /Query /TN "\OpenClawQuickCheck" /FO LIST /V 2>/dev/null | awk -F": +" "/Last Run Time|Last Result|Next Run Time|Scheduled Task State/{print \$1\": \"\$2}"'

