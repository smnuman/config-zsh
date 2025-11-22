#!/usr/bin/env zsh
# ~/.config/zsh/lib/pathtools.zsh
# The file is added in my shell(by .zshrc) from $ZDOTDIR/lib/pathtools.zsh
# Best to source it from $ZDOTDIR/zsh-exports before any export PATH commands

# Clean start - delete previous session path logs
[[ -f "$ZLOGDIR/pathlog.zlog" ]] && rm -f "$ZLOGDIR/pathlog.zlog"

# Usage e.g.: export_path "$HOME/.cargo/bin"
export_path() {
    local dir="$1" dirprint dirlength=0 sender
    local caller_info="${2:-${${(%):-%x}:-MAIN}}"   # caller info passed in
    caller_info="${caller_info//$HOME/~}"
    local log_file="$ZLOGDIR/pathlog.zlog"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    # local before="$PATH"

    # Canonicalise input: expand ~ and strip trailing slash
    dir="${dir%/}"
    dir="${dir/#\~/$HOME}"

    dirlength=30
    dirprint="${dir/#$HOME/~}"
    dirprint="${dirprint}$(printf '%*s' $(($dirlength-${#dirprint})) '')"

    sender="export_path (${${funcstack[2]}:t})"

    mkdir -p "${log_file:h}"  # create logs dir if missing

    [[ ! -d "$dir" ]] && {
        sender="${sender}$(printf '%*s' $((34-${#sender})) '')"
        $ZUTILS/zshlog --error -f "$log_file" " \e[0m<%K{red} ${sender}%k>:%K{red} ❌ Skipped: %F{white}$dirprint%f not found / not a directory (called by ${caller_info:t}) %k"
        return 1
    }

    for existing in ${(s/:/)PATH}; do
        [[ "$existing" == "$dir" ]] && {
            echo "export_path: ⚠️   Skipped: $dir already in PATH"
            echo "[$timestamp] :$sender: ⚠️   Already present: $dirprint (called by ${caller_info})" >> "$log_file"
            return
        }
    done

    # Add and export
    PATH="$dir:$PATH"
    \export PATH

    # local after="$PATH"
    # echo "export_path: ✅  Added: ${dir/#$HOME/~}"
    # {
    #     echo "[$timestamp] ✅ PATH UPDATED: ${dir/#$HOME/~} (triggered by $caller_info)"
    # } >> "$log_file"
    sender="${sender}$(printf '%*s' $((35-${#sender})) '')"
    $ZUTILS/zshlog --info -f "$log_file" " \e[0m<\e[0;33m$sender\e[0m>: \e[0;32m✅ Added:\e[0m "${dirprint}" (\e[32mcalled by ${caller_info:t}\e[0m) "
}

alias export='noglob _export_with_log'

_export_with_log() {
    if [[ "$1" == PATH=* ]]; then
        local rhs="${1#PATH=}"                      # Extract the right-hand side
        IFS=':' read -r -A dirs <<< "$rhs"          # Split by colon and add each directory individually
        for d in "${dirs[@]}"; do
            d="${d/#\~/$HOME}"
            d="${d%/}"
            export_path "$d" "${(%):-%x}:${LINENO}:${funcstack[2]}"
        done
        shift
    fi

    # Call the real export for everything else if there are arguments
    [[ $# -gt 0 ]] && builtin export "$@"
}

# Usage e.g.: dedup_path()
dedup_path() {
    local -a seen deduped
    for dir in ${(s/:/)PATH}; do
        [[ -d "$dir" && ! ${seen[(r)$dir]} ]] && deduped+="$dir" && seen+="$dir"
    done
    typeset -g PATH="${(j<:>)deduped}"
    print -P "%F{blue}🧹 PATH deduplicated:%f"
}

# Usage e.g.: remove_path "$HOME/.cargo/bin"
remove_path() {
    local target="$1" new_path=""
    for dir in ${(s/:/)PATH}; do
        [[ "$dir" != "$target" ]] && new_path+="$dir:"
    done
    typeset -g PATH="${new_path%:}"
    print -P "%F{red}❌ Removed from PATH:%f $target"
}

# Usage: path_audit_run ./install.sh or path_audit_run brew install ...
path_audit_run() {
    local cmd=("$@")
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local log_file="$ZLOGDIR/pathlog.zlog"

    mkdir -p "${log_file:h}"

    local before_formatted=$(echo "$PATH" | tr ':' '\n')

    echo "[$timestamp] 🚧 Running command: ${cmd[*]}" >> "$log_file"
    echo "    --- PATH BEFORE ---" >> "$log_file"
    echo "$before_formatted" | sed 's/^/    /' >> "$log_file"

    # Run the command
    "${cmd[@]}"

    local after_formatted=$(echo "$PATH" | tr ':' '\n')

    echo "    --- PATH AFTER ----" >> "$log_file"
    echo "$after_formatted" | sed 's/^/    /' >> "$log_file"

    echo "    --- DIFF (after - before) ---" >> "$log_file"
    diff <(echo "$before_formatted") <(echo "$after_formatted") | sed 's/^/    /' >> "$log_file"
    echo "" >> "$log_file"
}
