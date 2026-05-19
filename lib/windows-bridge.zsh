# =====================================================
# Windows Bridge Layer for WSL (stable abstraction)
# =====================================================

# ---- PowerShell direct execution ----
win_ps() {
  "$WIN_PS" -NoProfile "$@"
}

# ---- Windows user detection ----
win_user() {
  "$WIN_PS" -NoProfile -Command '$env:USERNAME' | tr -d '\r'
}

# ---- Windows home path ----
win_home() {
  echo "/mnt/c/Users/$WIN_USER"
}

# ---- VS Code (WSL-native recommended) ----
win_code() {
  # prefer WSL native VS Code integration
  if command -v $VSCODE_PATH/code >/dev/null 2>&1; then
    $VSCODE_PATH/code "${1:-.}"
  else
    echo "❌ VS Code CLI not installed in WSL"
  fi
}

# ---- Windows Explorer ----
win_open() {
  local path="${1:-.}"

  if [[ -x /bin/wslpath ]]; then
    "$WIN_EXPLORER" "$(/bin/wslpath -w "$path")"
  else
    echo "⚠️ wslpath not found, using manual fallback"

    # avoid sed dependency entirely
    local win_path="${path/#\/mnt\/c/C:}"
    win_path="${win_path//\//\\}"

    "$WIN_EXPLORER" "$win_path"
  fi
}

# ---- Unified CLI entrypoint ----
win() {
  local cmd="$1"; shift
  case "$cmd" in
    ps|code|open) "win_$cmd" "$@" ;;
    user|home)    "win_$cmd" ;;
    *) echo "Usage: win {ps|user|home|code|open}" ;;
  esac
}
