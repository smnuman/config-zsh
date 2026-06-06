# ~/.zprofile — symlinked from ~/.config/zsh/lib/.zprofile
# Loaded once per login shell (before .zshrc). macOS only.
#
# Purpose: bring Homebrew onto PATH so `brew` and brew-installed CLIs are
# discoverable in login shells (Terminal.app, tmux, ssh, etc.).

# --- legacy single-arch version (kept commented for reference) ---
# eval "$(/opt/homebrew/bin/brew shellenv)"

# --- portable across Apple Silicon and Intel Macs ---
if [[ -x /opt/homebrew/bin/brew ]]; then
  # Apple Silicon
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  # Intel Mac
  eval "$(/usr/local/bin/brew shellenv)"
fi
