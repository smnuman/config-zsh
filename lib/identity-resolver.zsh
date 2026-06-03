# =====================================================
# Cross-Platform Identity Resolver (CPIR)
# =====================================================

# ---------- helpers ----------
_trim() {
  tr -d '\r\n'
}

# ---------- Linux identity ----------
linux_user() {
  whoami
}

linux_home() {
  echo "$HOME"
}

# ---------- Windows identity (robust) ----------
win_user() {
  "$WIN_PS" -NoProfile -Command '$env:USERNAME' 2>/dev/null | _trim
}

win_home_raw() {
  "$WIN_PS" -NoProfile -Command '[Environment]::GetFolderPath("UserProfile")' 2>/dev/null | _trim
}

win_home() {
  local raw
  raw="$(win_home_raw)"

  if command -v wslpath >/dev/null 2>&1; then
    wslpath "$raw"
  else
    # fallback conversion
    echo "$raw" | sed 's|^C:|/mnt/c|; s|\\|/|g'
  fi
}

# ---------- unified interface ----------
sys() {
  case "$1" in
    user|linux_user)    linux_user ;;
    home|linux_home)    linux_home ;;
    win_user)           win_user ;;
    win_home)           win_home ;;
    *)
      echo "Usage: sys {user|home|win_user|win_home|linux_user|linux_home}"
      ;;
  esac
}