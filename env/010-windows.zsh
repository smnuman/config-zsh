# Only load in WSL environments
# [[ -z "$WSL_DISTRO_NAME" ]] && return
[[ "$PLATFORM" != "wsl" ]] && return

# ===== Windows Identity — vars assigned BEFORE path_add uses them =====
echo "executing WINDOWS bridge layer for WSL..."
WIN_ROOT="/mnt/c/Windows"
WIN_PS="$WIN_ROOT/System32/WindowsPowerShell/v1.0/powershell.exe"
WIN_CMD="$WIN_ROOT/System32/cmd.exe"
WIN_EXPLORER="$WIN_ROOT/explorer.exe"
WIN_HOME="/mnt/c/Users/smnum"

path_add "$WIN_ROOT"
path_add "$WIN_ROOT/System32"
path_add "$WIN_ROOT/System32/WindowsPowerShell/v1.0"

export WIN_ROOT WIN_PS WIN_CMD WIN_EXPLORER WIN_HOME

# =====================================================
