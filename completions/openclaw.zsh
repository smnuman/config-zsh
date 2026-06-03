# =========================================
# OpenClaw Completion Plugin
# =========================================

command -v openclaw >/dev/null 2>&1 || return

local dir="$HOME/.openclaw/completions"
local file="$dir/openclaw.zsh"

mkdir -p "$dir"

# Generate only if missing or empty
if [[ ! -s "$file" ]]; then
  openclaw completion > "$file"
fi

# Load it
[[ -s "$file" ]] && source "$file"
