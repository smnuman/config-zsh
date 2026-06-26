# ===== Safe PATH handling =====

# path_add() {
#     [[ -d "$1" ]] || return

#     case ":$PATH:" in
#         *":$1:"*) ;;
#         *) PATH="$1:$PATH" ;;
#     esac
# }

# ===== Add paths below =====

# Linux user tools
path_add "$HOME/.local/bin"
path_add "$HOME/bin"

# Rust toolchain (cargo-installed binaries — guardy, etc.)
path_add "$HOME/.cargo/bin"

# Windows CLI tools (optional but safe)
if [[ "$PLATFORM" == "wsl" ]]; then
    path_add "$WIN_ROOT"
    path_add "$WIN_ROOT/System32"
    path_add "$WIN_ROOT/System32/WindowsPowerShell/v1.0"
fi
# path_add "$VSCODE_PATH"
# path_add "/mnt/c/Users/smnum/AppData/Local/Programs/Microsoft VS Code/bin"

# ===== export the path now =====
export PATH
# echo "\tNew path env is: \n${PATH//:/\\n}"
