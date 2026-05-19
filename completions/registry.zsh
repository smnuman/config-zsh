# =========================================
# Completion Registry
# =========================================

# Helper: safe loader
zcomp_load() {
  local file="$1"
  [[ -f "$file" ]] && source "$file"
}

# Load plugins (explicit, predictable)
zcomp_load "$ZDOTDIR/completions/openclaw.zsh"
zcomp_load "$ZDOTDIR/completions/fzf.zsh"

# Future:
# zcomp_load "$ZDOTDIR/completions/docker.zsh"
# zcomp_load "$ZDOTDIR/completions/kubectl.zsh"
