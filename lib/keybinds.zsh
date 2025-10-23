# ===============================
#  🧭 Zsh Keybinds Configuration
#  Source: ~/.config/zsh/lib/keybinds.zsh
# ===============================

# --- 1️⃣ Base Mode ---
bindkey -e                               # Emacs keybindings for sane defaults
# --- classic Emacs bindings ---
bindkey '^T' transpose-chars             # Swap last two characters
bindkey '^K' kill-line                   # Delete from cursor to end of line
bindkey '^Y' yank                        # Paste last killed text

# --- 2️⃣ Basic Editing ---
bindkey '^?' backward-delete-char        # Backspace (ASCII DEL)
bindkey '^H' backward-delete-char        # Sometimes Backspace is CTRL-H
bindkey '^[[3~' delete-char              # Forward Delete (Fn+Delete or Del key or Ctrl+D)
bindkey '^D' delete-char                 # Ctrl+D (alternative forward delete)

# --- 3️⃣ Word & Line Deletion ---
bindkey '^W' backward-kill-word          # CTRL-W: delete previous word
bindkey '^U' kill-whole-line             # CTRL-U: delete entire line
bindkey '^[^H' backward-kill-word        # ESC + CTRL-H (macOS Option+Backspace)
bindkey '^[^?' backward-kill-word        # ESC + DEL (macOS Option+Backspace)

# --- 4️⃣ Navigation ---
bindkey '^[[A' up-line-or-search         # ↑ arrow: search through history
bindkey '^[[B' down-line-or-search       # ↓ arrow: same, forward
bindkey '^[[C' forward-char              # → arrow: forward char
bindkey '^[[D' backward-char             # ← arrow: backward char

# --- 5️⃣ History Search (optional enhancement) ---
bindkey '^P' history-search-backward    # Ctrl+P for previous matching command
bindkey '^N' history-search-forward     # Ctrl+N for next matching command
autoload -Uz up-line-or-beginning-search
autoload -Uz down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

# --- 6️⃣ Quick Cursor Movement (optional) ---
bindkey '^[f' forward-word               # Alt+F → forward one word
bindkey '^[b' backward-word              # Alt+B → backward one word
bindkey '^A' beginning-of-line           # Ctrl+A → go to start of line
bindkey '^E' end-of-line                 # Ctrl+E → go to end of line

# --- 7️⃣ Clear & Misc ---
bindkey '^L' clear-screen                # Ctrl+L → clear terminal
bindkey '^R' history-incremental-search-backward  # Ctrl+R → reverse search
