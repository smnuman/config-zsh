# # ===== Shared Workspaces =====
# if [[ "$PLATFORM" == "wsl" ]]; then
#     export CLAUDE_WS="$WIN_HOME/workspace"
#     export PROJECTS_WS="$WIN_HOME/projects"
#     # DEPRECATED (kept for compatibility only)
#     export VSCODE_PATH="$WIN_HOME/AppData/Local/Programs/Microsoft VS Code/bin"
#     # modern abstraction
#     export VSCODE_BIN="$VSCODE_PATH"
# fi
# # Optional convenience dirs
# ln -sfn "$CLAUDE_WS" "$HOME/workspace"
# ln -sfn "$PROJECTS_WS" "$HOME/projects"

# ===== Shared Workspaces =====

if [[ "$PLATFORM" == "wsl" ]]; then
    # echo "Setting up shared workspaces for WSL..."
    export CLAUDE_WS="$WIN_HOME/workspace"
    export PROJECTS_WS="$WIN_HOME/projects"
    # DEPRECATED (kept for compatibility only)
    export VSCODE_PATH="$WIN_HOME/AppData/Local/Programs/Microsoft VS Code/bin"
    # modern abstraction
    export VSCODE_BIN="$VSCODE_PATH"
else
    # echo "Not WSL, skipping shared workspace setup"
    export CLAUDE_WS="$HOME/workspace"
    export PROJECTS_WS="$HOME/projects"
fi
