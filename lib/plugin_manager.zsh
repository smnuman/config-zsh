# ~/.config/zsh/lib/plugin_manager.zsh
# Original: GitHub: https://github.com/ChristianChiarulli/machfiles/tree/new YouTube: chris@machine
# Modified by: Numan Syed
# Description: A plugin manager for ZSH.
# Version: 1.0.0
# License: MIT License
# Date: July 2025

# Set default log directory & file name for all zshlog -f "$LOGFILE" calls
# Set default local log directory (e.g.~/.config/zsh/locallogs)
local ZLOGDLOCAL=
local LOGFILE="plugin-manager.zlog"

# If the function zshlog_usage is not defined, source the file.
[[ ! -f zshlog_usage ]] && . "$ZUTILS/zsh-utils.zsh"

git_clone() {
    [[ $# -eq 0 ]] && { echo "\n\t===\n\t⚠️  Usage: git_clone <repo> <dest> \n\t===\n"; return 0; }

    local REPO="$1" DEST="$2"
    local CALLER="\e[0;42m${funcstack[2]}\e[0m"

    zshlog -f "$LOGFILE" -n " <$CALLER> : \e[0;32mCloning \e[0;42m $REPO\e[31m → \e[0;42m $DEST \e[0m"

    git clone --depth=1 "git@github.com:$REPO.git" "$DEST" && return 0

    zshlog -f "$LOGFILE" -v -t " <$CALLER> \e[33;47m:❌ Failed to clone $REPO.git \e[0m" && return 1
}

zsh_add_file() {
    local CALLER="${funcstack[2]}"

    [[ -f "$ZDOTDIR/$1" ]] && source "$ZDOTDIR/$1" && {
        zshlog -f "$LOGFILE" --log " <\e[0;33m$CALLER\e[0m>: \e[0;32mFile\e[0m \"$1\" \e[32msourced successfully\e[0m "
        return 0
    } || return 1
}

zsh_add_plugin() {
    local REPO="$1"
    local PLUGIN_NAME="${REPO##*/}"
    local PLUGIN_PATH="$ZDOTDIR/plugins/$PLUGIN_NAME"

    # if folder is not available, clone it from github
    [[ ! -d "$PLUGIN_PATH" ]] && git_clone $REPO $PLUGIN_PATH

    # Source the plugin-file : either of the 2 possible ones
    local TRY1="plugins/$PLUGIN_NAME/$PLUGIN_NAME.plugin.zsh"
    local TRY2="plugins/$PLUGIN_NAME/$PLUGIN_NAME.zsh"
    { zsh_add_file "$TRY1" || zsh_add_file "$TRY2" ;} || \
    { zshlog -f "$LOGFILE" --error -v -t "===\e[0;31m:❌ Couldn't source file: \e[36m["$TRY1"]\e[31m or \e[36m["$TRY2"]\e[31m \e[0m==="; }
    # { echo -e "\t===\e[0;31;47m zsh_add_plugin:❌ Couldn't source file: \e[36m["$TRY1"]\e[31m or \e[36m["$TRY2"]\e[31m \e[0m==="; }
}

zsh_add_completion() {
    local REPO="$1"
    local DO_COMPINIT="$2"
    local PLUGIN_NAME="${REPO##*/}"
    local PLUGIN_PATH="$ZDOTDIR/plugins/$PLUGIN_NAME"
    local LOCAL_PATH="$ZDOTDIR/completions"
    local LOCAL_FILE="${LOCAL_PATH}/_${REPO}"

    if [[ "$REPO" == */* ]]; then
        [[ ! -d "$PLUGIN_PATH" ]] && { git_clone "$REPO" "$PLUGIN_PATH" || { zshlog -f "$LOGFILE" -t -l error "❌ Failed to clone completion plugin: $REPO"; return 1; } } || \
        zshlog -f "$LOGFILE" --warn "Plugin $PLUGIN_NAME already exists, skipping clone."

        zsh_add_file "plugins/$PLUGIN_NAME/$PLUGIN_NAME.plugin.zsh" || \
        { zshlog -f "$LOGFILE" --error -t "===\e[0;31;47m:❌ Missing completions source: [${PLUGIN_PATH:-$HOME/~}/$PLUGIN_NAME.plugin.zsh] \e[0m==="; }

        setopt local_options null_glob
        local compfiles=($PLUGIN_PATH/_*)
        if (( ${#compfiles[@]} > 0 )); then
            fpath=("$PLUGIN_PATH" $fpath)
            zshlog -f "$LOGFILE" --log "➕ Added completion plugin '$PLUGIN_NAME' to fpath."
        fi
    elif [[ -f "$LOCAL_FILE" ]]; then
        fpath=("$LOCAL_PATH" $fpath)
        zshlog -f "$LOGFILE" --log "➕ Added local completion '${LOCAL_FILE##*/}' to fpath."
    else
        zshlog -f "$LOGFILE" --warn -t "⚠️  No completion found for '$REPO' (remote or local)."
    fi

    # Initialise completion system only once
    if [[ "$DO_COMPINIT" == true ]]; then
        zsh_compinit_once
    fi
}

# Run compinit exactly once per shell session
zsh_compinit_once() {
    # Return if already run
    [[ -n "$__COMPINIT_RAN" ]] && return 0

    # Load compinit if missing
    if ! whence compinit >/dev/null; then
        autoload -Uz compinit
    fi

    # Root shells get -u to skip insecure dir checks
    if [[ $EUID -eq 0 ]]; then
        zshlog -f "$LOGFILE" --warn "⚠️  Running compinit in root shell with -u (skipping security check)."
        compinit -u
    else
        compinit
    fi

    __COMPINIT_RAN=1
    zshlog -f "$LOGFILE" "✅ Compinit initialised."
}

zsh_update_plugins() {
    for DIR in "$ZDOTDIR"/plugins/*/.git; do
        local PLUGIN_PATH="${DIR%/.git}"
        zshlog -f "$LOGFILE" "Updating ${PLUGIN_PATH##*/}..."
        git -C "$PLUGIN_PATH" pull --quiet --rebase && zshlog -f "$LOGFILE" "...done" || zshlog -f "$LOGFILE" --error "...failed ❌"
    done
}

zsh_auto_update_plugins() {
    # running as a cronjob, variables are localized, as we need to store the variables in a file
    local ZDOTLOGS="$HOME/.config/zsh/logs"
    local CACHE_FILE="$ZDOTLOGS/plugin-update.timestamp"
    local LOG_FILE="$ZDOTLOGS/plugin-update.log"
    local NOW=$(date +%s)
    local WEEK_SECONDS=$((7 * 24 * 60 * 60))

    mkdir -p "$ZDOTLOGS"

    if [[ ! -f "$CACHE_FILE" ]] || (( NOW - $(cat "$CACHE_FILE") > WEEK_SECONDS )); then
        echo "[$(date)] Updating Zsh plugins..." | tee -a "$LOG_FILE"
        zsh_update_plugins 2>&1 | tee -a "$LOG_FILE"
        echo "$NOW" >| "$CACHE_FILE"
    fi
}
