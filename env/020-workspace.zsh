# ===== Shared Workspaces =====

export CLAUDE_WS="$WIN_HOME/workspace"
export PROJECTS_WS="$WIN_HOME/projects"
export VSCODE_PATH="$WIN_HOME/AppData/Local/Programs/Microsoft VS Code/bin"

# Optional convenience dirs
ln -sfn "$CLAUDE_WS" "$HOME/workspace"
ln -sfn "$PROJECTS_WS" "$HOME/projects"
