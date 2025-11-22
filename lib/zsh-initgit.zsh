#!/usr/bin/env zsh
# ~/.config/zsh/zsh-initgit

local logfile="$ZLOGDIR/$ZLOGFILE"
local stamp=$(date '+%Y-%m-%d %H:%M:%S')

# === Enforce SSH for GitHub remotes if not already set ===
if ! git config --global --get url."git@github.com:".insteadOf >/dev/null; then
    git config --global url."git@github.com:".insteadOf "https://github.com/"
fi

tmpfile="${ZDOTDIR}/git-utils/git_users.tmp"
:>"$tmpfile"

# export GIT_PROVIDER="github"    # or "gitlab" (default: github)

if [[ -z "$GITHUB_USER" ]]; then
  email=$(git config user.email 2>/dev/null)
#   [[ -n "$email" ]] && { export GITHUB_USER="${email%@*}" } || {
    [[ -n "$email" ]] && { echo "export GITHUB_USER=\"${email%@*}\"" >> "$tmpfile"; } || {\
      [[ "$ZSH_DEBUG_BOOT" == "false" ]] || echo "[${stamp}]\t.zshrc -> zsh-initgit: GITHUB_USER not set and could not be inferred from git config"
    echo "\"${stamp}\",\t\".zshrc -> zsh-initgit\", \"GITHUB_USER not set and could not be inferred from git config\"" >> "${logfile}"
  }
fi

# --- GitLab user with multiple retries and fallback ---
if [[ -z "$GITLAB_USER" ]]; then
  for i in {1..5}; do
    username=$(glab api user 2>/dev/null | jq -r '.username' 2>/dev/null)
    [[ -n "$username" ]] && break
    sleep 1
  done
#   [[ -n "$username" ]] && { export GITLAB_USER="${username}" } || {\
  [[ -n "$username" ]] && { echo "export GITLAB_USER="${username}" " >> "$tmpfile"; } || {\
    echo "export GITLAB_USER="${username:-$(git config user.name 2>/dev/null)}" " >> "$tmpfile";
    [[ "$ZSH_DEBUG_BOOT" == "false" ]] || echo "${stamp}\t.zshrc -> zsh-initgit: GITLAB_USER not properly set or inferred from git config" ;
    echo "\"${stamp}\",\t\".zshrc -> zsh-initgit\", \"GITLAB_USER not properly set or inferred from git config\"" >> "${logfile}";
  }
fi

mv "$tmpfile" "${ZDOTDIR}/git-utils/git_users.zsh"
