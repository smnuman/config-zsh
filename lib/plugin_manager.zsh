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

# Clean start - empty previous session logs (keep file for consistency)
[[ -f "$ZLOGDIR/$LOGFILE" ]] && : > "$ZLOGDIR/$LOGFILE"

# If the function zshlog_usage is not defined, source the file.
# [[ ! -f zshlog_usage ]] && . "$ZUTILS/zsh-utils.zsh"

git_clone() {
    [[ $# -eq 0 ]] && { echo "\n\t===\n\t⚠️  Usage: git_clone <repo> <dest> \n\t===\n"; return 0; }

    local REPO="$1" DEST="$2"
    local CALLER="\e[0;42m${funcstack[2]}\e[0m"

    # Log cloning operation unless in performance mode
    [[ "$ZSH_PERF_MODE" != "true" ]] && $ZUTILS/zshlog -f "$LOGFILE" -n " <$CALLER> : \e[0;32mCloning \e[0;42m $REPO\e[31m → \e[0;42m $DEST \e[0m"

    # Use optimized git clone options
    git clone --depth=1 --single-branch ${ZSH_PERF_MODE:+--quiet} "git@github.com:$REPO.git" "$DEST" 2>/dev/null && return 0

    $ZUTILS/zshlog -f "$LOGFILE" -v -t " <$CALLER> \e[33;47m:❌ Failed to clone $REPO.git \e[0m" && return 1
}

# Actual routine:
# zsh_add_file() {
#   [ -f "$ZDOTDIR/$1" ] && source "$ZDOTDIR/$1"
# }
# Rest are error handling and logging
# Function call: zsh_add_file <file_name_relative_to_ZDOTDIR>
zsh_add_file() {
    [[ -f "$ZDOTDIR/$1" ]] && source "$ZDOTDIR/$1" && {
        # Always log but optimize format in performance mode
        if [[ "$ZSH_PERF_MODE" == "true" ]]; then
            # Simple logging format - maintains logging requirement with minimal overhead
            $ZUTILS/zshlog -f "$LOGFILE" --log "zsh_add_file: $1 sourced"
        else
            # Original detailed formatting for normal mode
            local CALLER="${funcstack[1]:t} (${funcstack[2]:t})"
            local filename=$1; filename_len=$([[ $CALLER == *"init"* ]] && echo 40 || echo 95 )
            CALLER="${CALLER}$(printf '%*s' $((35-${#CALLER})) '')"
            filename="${filename}$(printf '%*s' $(($filename_len-${#filename})) '')"
            $ZUTILS/zshlog -f "$LOGFILE" --log " <\e[0;33m${CALLER}\e[0m>: \e[0;32mFile\e[0m $filename \e[32msourced successfully\e[0m "
        fi
        return 0
    } || return 1

    # # Skip expensive formatting if performance mode enabled
    # if [[ "$ZSH_PERF_MODE" == "true" ]]; then
    #     [[ -f "$ZDOTDIR/$1" ]] && source "$ZDOTDIR/$1"
    #     return $?
    # fi

    # # Original formatting for normal mode (maintain full zshlog structure)
    # local CALLER="${funcstack[1]:t} (${funcstack[2]:t})"
    # local filename=$1; filename_len=$([[ $CALLER == *"init"* ]] && echo 40 || echo 95 )
    # CALLER="${CALLER}$(printf '%*s' $((35-${#CALLER})) '')"
    # filename="${filename}$(printf '%*s' $(($filename_len-${#filename})) '')"

    # [[ -f "$ZDOTDIR/$1" ]] && source "$ZDOTDIR/$1" && {
    #     $ZUTILS/zshlog -f "$LOGFILE" --log " <\e[0;33m${CALLER}\e[0m>: \e[0;32mFile\e[0m $filename \e[32msourced successfully\e[0m "
    #     return 0
    # } || return 1
}

# Actual routine:
# function zsh_add_plugin() {
#     local REPO="$1"
#     local PLUGIN_NAME="${REPO##*/}"
#     # if folder is not available, clone it from github
#     [ ! -d "$ZDOTDIR/plugins/$PLUGIN_NAME" ] && git clone "https://github.com/$REPO.git" "$ZDOTDIR/plugins/$PLUGIN_NAME"
#     # Source the plugin-file : either of the 2 possible ones
#     zsh_add_file "plugins/$PLUGIN_NAME/$PLUGIN_NAME.plugin.zsh" || \
#     zsh_add_file "plugins/$PLUGIN_NAME/$PLUGIN_NAME.zsh"
# }
# Rest are error handling and logging
# Function call: zsh_add_plugin <github_repo>
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
    { $ZUTILS/zshlog -f "$LOGFILE" --error -v -t "===\e[0;31m:❌ Couldn't source file: \e[36m["$TRY1"]\e[31m or \e[36m["$TRY2"]\e[31m \e[0m==="; }
    # { echo -e "\t===\e[0;31;47m zsh_add_plugin:❌ Couldn't source file: \e[36m["$TRY1"]\e[31m or \e[36m["$TRY2"]\e[31m \e[0m==="; }
}

# Actual routine:
# function zsh_add_completion() {
#     local REPO="$1"
#     local DO_COMPINIT="$2"
#     local PLUGIN_NAME="${REPO##*/}"
#     if [ ! -d "$ZDOTDIR/plugins/$PLUGIN_NAME" ]; then
#         git clone "https://github.com/$REPO.git" "$ZDOTDIR/plugins/$PLUGIN_NAME"
#         # fpath+=$(ls $ZDOTDIR/plugins/$PLUGIN_NAME/_*)
#     fi
#     # For completions -- get all files starting with _* in the plugin dir
#     completion_file_path=$(ls $ZDOTDIR/plugins/$PLUGIN_NAME/_*)
#     fpath+="$(dirname "${completion_file_path}")"
#     zsh_add_file "plugins/$PLUGIN_NAME/$PLUGIN_NAME.plugin.zsh"
#     completion_file="$(basename "${completion_file_path}")"
#     if [ "$DO_COMPINIT" = true ] && compinit "${completion_file:1}"
# }
# Rest are error handling and logging
# Function call: zsh_add_completion <github_repo> <true|false>
zsh_add_completion() {
    local CALLER="${funcstack[1]:t} (${funcstack[2]:t})"; CALLER="${CALLER}$(printf '%*s' $((35-${#CALLER})) '')"
    local REPO="$1"
    local DO_COMPINIT="$2"
    local PLUGIN_NAME="${REPO##*/}"
    local PLUGIN_PATH="$ZDOTDIR/plugins/$PLUGIN_NAME"
    local LOCAL_PATH="$ZDOTDIR/completions"
    local LOCAL_FILE="${LOCAL_PATH}/_${REPO}"

    if [[ "$REPO" == */* ]]; then
        [[ ! -d "$PLUGIN_PATH" ]] && { git_clone "$REPO" "$PLUGIN_PATH" || { $ZUTILS/zshlog -f "$LOGFILE" -t -l error " \e[0;33m${CALLER}\e[0m>: ❌ Failed to clone completion plugin: $REPO"; return 1; } } || \
        $ZUTILS/zshlog -f "$LOGFILE" --warn " <\e[0;33m${CALLER}\e[0m>: \e[0;32mPlugin\e[0m %K{green} $PLUGIN_NAME %k \e[0;32malready exists, skipping clone\e[0m."

        zsh_add_file "plugins/$PLUGIN_NAME/$PLUGIN_NAME.plugin.zsh" || \
        { $ZUTILS/zshlog -f "$LOGFILE" --error -t " <\e[0;33m${CALLER}\e[0m>: \e[0;32m===\e[0;31;47m:❌ Missing completions source: [${PLUGIN_PATH:-$HOME/~}/$PLUGIN_NAME.plugin.zsh] \e[0m==="; }

        setopt local_options null_glob
        local compfiles=($PLUGIN_PATH/_*)
        if (( ${#compfiles[@]} > 0 )); then
            fpath=("$PLUGIN_PATH" $fpath)
            $ZUTILS/zshlog -f "$LOGFILE" --log " <\e[0;33m${CALLER}\e[0m>: \e[0;32m✅ Added completion plugin\e[0;32m '$PLUGIN_NAME' \e[0;32mto fpath\e[0m."
        fi
    elif [[ -f "$LOCAL_FILE" ]]; then
        fpath=("$LOCAL_PATH" $fpath)
        $ZUTILS/zshlog -f "$LOGFILE" --log " <\e[0;33m${CALLER}\e[0m>: \e[0;32m✅ Added local completion\e[0m '${LOCAL_FILE##*/}' \e[0;32mto fpath\e[0m."
    else
        $ZUTILS/zshlog -f "$LOGFILE" --warn -t " <\e[0;33m${CALLER}\e[0m>: \e[0;34m⚠️  No completion found for\e[0m '$REPO' \e[0;34m(remote or local)\e[0m."
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

    local CALLER="${funcstack[1]:t} (${funcstack[2]:t})"; CALLER="${CALLER}$(printf '%*s' $((35-${#CALLER})) '')"; CALLER="%F{yellow}${CALLER}%f"

    # Load compinit if missing
    if ! whence compinit >/dev/null; then
        autoload -Uz compinit
    fi

    # Root shells get -u to skip insecure dir checks
    if [[ $EUID -eq 0 ]]; then
        $ZUTILS/zshlog -f "$LOGFILE" --warn "⚠️  Running compinit in root shell with -u (skipping security check)."
        compinit -u
    else
        compinit
    fi

    __COMPINIT_RAN=1
    $ZUTILS/zshlog -f "$LOGFILE" " <${(q)CALLER}>: ✅ Compinit initialised."
}

zsh_update_plugins() {
    for DIR in "$ZDOTDIR"/plugins/*/.git; do
        local PLUGIN_PATH="${DIR%/.git}"
        $ZUTILS/zshlog -f "$LOGFILE" "Updating ${PLUGIN_PATH##*/}..."
        git -C "$PLUGIN_PATH" pull --quiet --rebase && $ZUTILS/zshlog -f "$LOGFILE" "$(basename "$DIR").git ...done" || $ZUTILS/zshlog -f "$LOGFILE" --error "$(basename "$DIR").git ...failed ❌"
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
