# --- Initialise fzf and zoxide ---
# if command -v fzf >/dev/null 2>&1; then
if (( $+commands[fzf] )); then
  local fzf_prefix=${$(brew --prefix 2>/dev/null):-/usr/local}/opt/fzf
  for fzf_source in ~/.fzf/shell "$fzf_prefix/shell"; do
    [[ -f "$fzf_source/completion.zsh" ]] && . "$fzf_source/completion.zsh"
    [[ -f "$fzf_source/key-bindings.zsh" ]] && . "$fzf_source/key-bindings.zsh"
  done
  # Initialize fzf for zsh
  eval "$(fzf --zsh)"
fi

# Initialise zoxide for zsh
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
# =====================================================
