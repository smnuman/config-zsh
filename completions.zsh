# Prevent double loading
[[ -n "$ZSH_COMPLETIONS_LOADED" ]] && return
export ZSH_COMPLETIONS_LOADED=1

autoload -Uz compinit
compinit -C

fpath=(
  "$HOME/.local/share/zsh/site-functions"
  "$ZDOTDIR/completions"
  "$HOME/.openclaw/completions"
  $fpath
)

[[ -f "$ZDOTDIR/completions/registry.zsh" ]] && \
  source "$ZDOTDIR/completions/registry.zsh"
