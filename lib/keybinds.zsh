# Source it with my plugin manager, from ~/.zshrc
bindkey -e  # Emacs keybindings for sane defaults

# Fix Backspace + Delete
bindkey '^?' backward-delete-char         # Backspace (ASCII DEL)
bindkey '^H' backward-delete-char         # Sometimes Backspace is CTRL-H
bindkey '^[[3~' delete-char               # Forward Delete (Del key)

# Word + Line deletion (Option+Backspace / Command+Backspace)
bindkey '^W' backward-kill-word           # Normal CTRL-W
bindkey '^U' kill-whole-line              # Normal CTRL-U

# macOS/iTerm sends ESC + DEL sometimes for Option+Backspace
bindkey '^[^H' backward-kill-word         # ESC + CTRL-H
bindkey '^[^?' backward-kill-word         # ESC + DEL

# Arrow keys
bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search
bindkey '^[[C' forward-char
bindkey '^[[D' backward-char
