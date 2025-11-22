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

# === COMMENTED OUT: Complex optimizations that added overhead ===
# declare -gA __PLUGIN_LOAD_STATE
# declare -ga __ASYNC_PLUGIN_JOBS
# declare -ga __PENDING_COMPLETIONS
# __ASYNC_PLUGIN_MODE="false"
# __LAZY_COMPLETION_MODE="false"

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
# === SIMPLE VERSION: Original ChristianChiarulli approach ===
# Function to source files if they exist
zsh_add_file() {
    [ -f "$ZDOTDIR/$1" ] && source "$ZDOTDIR/$1"
}

# === COMMENTED OUT: Complex logging version that was slower ===
# zsh_add_file() {
#     [[ -f "$ZDOTDIR/$1" ]] && source "$ZDOTDIR/$1" && {
#         # Always log but optimize format in performance mode
#         if [[ "$ZSH_PERF_MODE" == "true" ]]; then
#             # Simple logging format - maintains logging requirement with minimal overhead
#             $ZUTILS/zshlog -f "$LOGFILE" --log "zsh_add_file: $1 sourced"
#         else
#             # Original detailed formatting for normal mode
#             local CALLER="${funcstack[1]:t} (${funcstack[2]:t})"
#             local filename=$1; filename_len=$([[ $CALLER == *"init"* ]] && echo 40 || echo 95 )
#             CALLER="${CALLER}$(printf '%*s' $((35-${#CALLER})) '')"
#             filename="${filename}$(printf '%*s' $(($filename_len-${#filename})) '')"
#             $ZUTILS/zshlog -f "$LOGFILE" --log " <\e[0;33m${CALLER}\e[0m>: \e[0;32mFile\e[0m $filename \e[32msourced successfully\e[0m "
#         fi
#         return 0
#     } || return 1
# }

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
# === SIMPLE VERSION: Original ChristianChiarulli approach ===
zsh_add_plugin() {
    PLUGIN_NAME=$(echo $1 | cut -d "/" -f 2)
    if [ -d "$ZDOTDIR/plugins/$PLUGIN_NAME" ]; then
        # For plugins
        zsh_add_file "plugins/$PLUGIN_NAME/$PLUGIN_NAME.plugin.zsh" || \
        zsh_add_file "plugins/$PLUGIN_NAME/$PLUGIN_NAME.zsh"
    else
        git clone "https://github.com/$1.git" "$ZDOTDIR/plugins/$PLUGIN_NAME"
    fi
}

# === COMMENTED OUT: Complex async plugin loading that added overhead ===
# _async_load_plugin() { ... }
# _sync_load_plugin() { ... }
# wait_and_source_plugins() { ... }

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
# === BACKGROUND COMPLETION LOADING ===
zsh_add_completion() {
    # Schedule completion loading in background
    (
        PLUGIN_NAME=$(echo $1 | cut -d "/" -f 2)
        if [ ! -d "$ZDOTDIR/plugins/$PLUGIN_NAME" ]; then
            git clone --quiet "https://github.com/$1.git" "$ZDOTDIR/plugins/$PLUGIN_NAME" 2>/dev/null
        fi

        if [ -d "$ZDOTDIR/plugins/$PLUGIN_NAME" ]; then
            completion_file_path=$(ls $ZDOTDIR/plugins/$PLUGIN_NAME/_* 2>/dev/null | head -1)
            if [ -n "$completion_file_path" ]; then
                # Signal completion ready
                echo "$ZDOTDIR/plugins/$PLUGIN_NAME" >> "$ZDOTDIR/.completion_paths" 2>/dev/null
            fi
        fi
    ) &

    # Store for potential immediate compinit
    [ "$2" = true ] && __NEEDS_COMPINIT=true
}

# Apply background-loaded completions (call after boot)
apply_background_completions() {
    [ ! -f "$ZDOTDIR/.completion_paths" ] && return 0

    while IFS= read -r completion_path; do
        [ -d "$completion_path" ] && fpath=("$completion_path" $fpath)
    done < "$ZDOTDIR/.completion_paths"

    # Run compinit if any completion requested it
    [ "$__NEEDS_COMPINIT" = true ] && { autoload -Uz compinit; compinit }

    # Cleanup
    rm -f "$ZDOTDIR/.completion_paths" 2>/dev/null
}

# === COMMENTED OUT: Complex completion loading that was slower ===
# _load_completion_now() {
#     local REPO="$1"
#     local DO_COMPINIT="$2"
#     local CALLER="${funcstack[2]:t} (${funcstack[3]:t})"; CALLER="${CALLER}$(printf '%*s' $((35-${#CALLER})) '')"
#     local PLUGIN_NAME="${REPO##*/}"
#     local PLUGIN_PATH="$ZDOTDIR/plugins/$PLUGIN_NAME"
#     local LOCAL_PATH="$ZDOTDIR/completions"
#     local LOCAL_FILE="${LOCAL_PATH}/_${REPO}"
#
#     if [[ "$REPO" == */* ]]; then
#         [[ ! -d "$PLUGIN_PATH" ]] && { git_clone "$REPO" "$PLUGIN_PATH" || { $ZUTILS/zshlog -f "$LOGFILE" -t -l error " \e[0;33m${CALLER}\e[0m>: ❌ Failed to clone completion plugin: $REPO"; return 1; } } || \
#         [[ "$ZSH_PERF_MODE" != "true" ]] && $ZUTILS/zshlog -f "$LOGFILE" --warn " <\e[0;33m${CALLER}\e[0m>: \e[0;32mPlugin\e[0m %K{green} $PLUGIN_NAME %k \e[0;32malready exists, skipping clone\e[0m."
#
#         zsh_add_file "plugins/$PLUGIN_NAME/$PLUGIN_NAME.plugin.zsh" || \
#         { $ZUTILS/zshlog -f "$LOGFILE" --error -t " <\e[0;33m${CALLER}\e[0m>: \e[0;32m===\e[0;31;47m:❌ Missing completions source: [${PLUGIN_PATH:-$HOME/~}/$PLUGIN_NAME.plugin.zsh] \e[0m==="; }
#
#         setopt local_options null_glob
#         local compfiles=($PLUGIN_PATH/_*)
#         if (( ${#compfiles[@]} > 0 )); then
#             fpath=("$PLUGIN_PATH" $fpath)
#             [[ "$ZSH_PERF_MODE" == "true" ]] && \
#                 $ZUTILS/zshlog -f "$LOGFILE" --log "Added completion: $PLUGIN_NAME" || \
#                 $ZUTILS/zshlog -f "$LOGFILE" --log " <\e[0;33m${CALLER}\e[0m>: \e[0;32m✅ Added completion plugin\e[0;32m '$PLUGIN_NAME' \e[0;32mto fpath\e[0m."
#         fi
#     elif [[ -f "$LOCAL_FILE" ]]; then
#         fpath=("$LOCAL_PATH" $fpath)
#         [[ "$ZSH_PERF_MODE" == "true" ]] && \
#             $ZUTILS/zshlog -f "$LOGFILE" --log "Added local completion: ${LOCAL_FILE##*/}" || \
#             $ZUTILS/zshlog -f "$LOGFILE" --log " <\e[0;33m${CALLER}\e[0m>: \e[0;32m✅ Added local completion\e[0m '${LOCAL_FILE##*/}' \e[0;32mto fpath\e[0m."
#     else
#         [[ "$ZSH_PERF_MODE" != "true" ]] && \
#             $ZUTILS/zshlog -f "$LOGFILE" --warn -t " <\e[0;33m${CALLER}\e[0m>: \e[0;34m⚠️  No completion found for\e[0m '$REPO' \e[0;34m(remote or local)\e[0m."
#     fi
#
#     # Initialise completion system only once
#     if [[ "$DO_COMPINIT" == true ]]; then
#         zsh_compinit_once
#     fi
# }

# === COMMENTED OUT: Complex completion batching that added overhead ===
# load_pending_completions() {
#     [[ ${#__PENDING_COMPLETIONS[@]} -eq 0 ]] && return 0

#     local entry repo do_compinit loaded=0 failed=0 need_compinit=false

#     for entry in "${__PENDING_COMPLETIONS[@]}"; do
#         repo="${entry%:*}"
#         do_compinit="${entry#*:}"
#
#         if _load_completion_now "$repo" false; then
#             ((loaded++))
#             [[ "$do_compinit" == "true" ]] && need_compinit=true
#         else
#             ((failed++))
#         fi
#     done
#
#     # Run compinit once at the end if needed
#     [[ "$need_compinit" == true ]] && zsh_compinit_once
#
#     # Log results
#     if [[ "$ZSH_PERF_MODE" == "true" ]]; then
#         $ZUTILS/zshlog -f "$LOGFILE" --log "load_pending_completions: Loaded $loaded completions, $failed failed"
#     else
#         [[ $loaded -gt 0 ]] && $ZUTILS/zshlog -f "$LOGFILE" --info "✅ Loaded $loaded completions"
#         [[ $failed -gt 0 ]] && $ZUTILS/zshlog -f "$LOGFILE" --warn "⚠️  Failed to load $failed completions"
#     fi
#
#     # Reset for next session
#     __PENDING_COMPLETIONS=()
# }

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
