# ~/.config/zsh/lib/prompts/numan.zsh

# Prompt function
# prompt_numan() {
numan() {
  # Colours
  local RED="%F{red}"
  local GREEN="%F{green}"
  local BLUE="%F{blue}"
  local RESET="%f"

  # Left prompt: user@host in green, path in blue
  PROMPT="${GREEN}%n@%m${RESET}:${BLUE}%~${RESET} $ "

  # Right prompt: optional git branch
  if type git &>/dev/null; then
    RPROMPT='$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")'
  fi
}

# Optional: call the function to initialize immediately
numan

