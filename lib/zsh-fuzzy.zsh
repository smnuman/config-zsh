if (( $+commands[fzf] )); then
  local fzf_prefix=""
  if [[ "$ZSH_PLATFORM" == "macos" ]] && (( $+commands[brew] )); then
    fzf_prefix="$(brew --prefix)/opt/fzf"
  fi
  [[ -z "$fzf_prefix" || ! -d "$fzf_prefix" ]] && fzf_prefix="/usr/share/doc/fzf"
  [[ -d "$fzf_prefix" ]] || fzf_prefix="/usr/share/fzf"
  for fzf_source in ~/.fzf/shell "$fzf_prefix/shell"; do
    [[ -f "$fzf_source/completion.zsh" ]] && . "$fzf_source/completion.zsh"
    [[ -f "$fzf_source/key-bindings.zsh" ]] && . "$fzf_source/key-bindings.zsh"
  done
  eval "$(fzf --zsh 2>/dev/null)" || true
fi

command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
