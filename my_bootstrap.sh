#!/usr/bin/env bash
# WSL Zsh Nomad Bootstrap (Safe, Update-Friendly)
# Maintains existing ~/.config/zsh files and plugins

set -euo pipefail

USER_NAME="numan"
ZSH_BIN="/usr/bin/zsh"
ZDOTDIR="$HOME/.config/zsh"

echo "✅ 1. Ensuring user exists: $USER_NAME"
if ! id "$USER_NAME" &>/dev/null; then
    echo "Creating user $USER_NAME..."
    adduser --gecos "$USER_NAME" "$USER_NAME"
fi

echo "✅ 2. Setting default shell for $USER_NAME to $ZSH_BIN"
current_shell=$(getent passwd "$USER_NAME" | cut -d: -f7)
if [[ "$current_shell" != "$ZSH_BIN" ]]; then
    chsh -s "$ZSH_BIN" "$USER_NAME" || echo "⚠️  PAM may block chsh in WSL, ignoring (already set in /etc/passwd)"
else
    echo "Shell already set to $ZSH_BIN"
fi

echo "✅ 3. Making $USER_NAME the default WSL user"
WSL_CONF="/etc/wsl.conf"
if ! grep -q "default=$USER_NAME" "$WSL_CONF" 2>/dev/null; then
    mkdir -p "$(dirname "$WSL_CONF")"
    echo -e "[user]\ndefault=$USER_NAME" >> "$WSL_CONF"
else
    echo "Default WSL user already $USER_NAME"
fi

echo "✅ 4. Installing Zsh if missing"
if ! command -v zsh &>/dev/null; then
    apt update && apt install -y zsh
fi

echo "✅ 5. Setting up modular .config/zsh for $USER_NAME (update-safe)"
mkdir -p "$ZDOTDIR/lib" "$ZDOTDIR/utils"

# Only create .zshrc if missing
ZSHRC_FILE="$ZDOTDIR/.zshrc"
if [[ ! -f "$ZSHRC_FILE" ]]; then
    cat > "$ZSHRC_FILE" <<'EOF'
# Modular Nomad Zsh bootstrap (update-safe)
export ZDOTDIR="$HOME/.config/zsh"

# Load environment
[[ -f "$ZDOTDIR/env.zsh" ]] && source "$ZDOTDIR/env.zsh"

# Load plugin manager
[[ -f "$ZDOTDIR/lib/plugin_manager.zsh" ]] && source "$ZDOTDIR/lib/plugin_manager.zsh"

# Load plugins/utils safely
plugin_manager_load_all 2>/dev/null || true

# WSL login fix
if [[ -r /proc/version ]] && grep -q Microsoft /proc/version; then
    export SHELL="/usr/bin/zsh"
    exec /usr/bin/zsh -l
fi
EOF
    echo "Created new ~/.config/zsh/.zshrc"
else
    echo "~/.config/zsh/.zshrc already exists, leaving it intact"
fi

echo "✅ 6. Done! Restart WSL to apply changes"
echo "   e.g., in PowerShell: wsl --shutdown"

