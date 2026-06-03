# ~/.config/zsh/utils/zsh-title.zsh
# Tab/window title management for OpenClaw
#
# Sets title only for interactive/TUI commands:
#   openclaw tui             →  "🦞 tui"
#   openclaw tui foo         →  "🦞 tui foo"
#   claw chat --local        →  "🦞 chat --local"
#   openclaw-tui             →  "🦞 TUI"
#
# Query/read-only commands (status, config, etc.) leave title alone.
# Resets to current directory (~ shorthand) on completion.
# Uses a state flag to avoid pgrep overhead on every prompt.

_claw_active=0

_claw_title_set() {
    printf '\e]2;%s\e\\' "$1"
}

_claw_title_reset() {
    printf '\e]2;%s\e\\' "${PWD/#$HOME/~}"
}

_claw_title_from_cmd() {
    local cmd="$1" sub

    # openclaw-tui (possibly with args)
    sub="${cmd#openclaw-tui}"
    if [[ "$sub" != "$cmd" ]]; then
        printf '🦞 TUI'
        return
    fi

    # openclaw chat|tui <subcommand>
    sub="${cmd#openclaw }"
    if [[ "$sub" != "$cmd" ]]; then
        sub="${sub## }"
        [[ ${#sub} -gt 55 ]] && sub="${sub:0:52}..."
        printf '🦞 %s' "$sub"
        return
    fi

    # claw chat|tui <subcommand>
    sub="${cmd#claw }"
    if [[ "$sub" != "$cmd" ]]; then
        sub="${sub## }"
        [[ ${#sub} -gt 55 ]] && sub="${sub:0:52}..."
        printf '🦞 %s' "$sub"
        return
    fi

    printf '🦞'
}

# Shell wrapper for invoking openclaw with title management
claw() {
    local title
    title=$(_claw_title_from_cmd "claw $*")
    _claw_title_set "$title"
    _claw_active=1
    command openclaw "$@"
    _claw_title_reset
    _claw_active=0
}

# preexec: called before every command
# Only activates for interactive/TUI subcommands.
_claw_preexec() {
    case "$1" in
        claw\ chat*|claw\ tui*|openclaw\ chat*|openclaw\ tui*|openclaw-tui*)
            _claw_title_set "$(_claw_title_from_cmd "$1")"
            _claw_active=1
            ;;
    esac
}

# precmd: called after every command completes
_claw_precmd() {
    (( _claw_active )) || return
    _claw_title_reset
    _claw_active=0
}

# Install hooks
autoload -Uz add-zsh-hook
add-zsh-hook preexec _claw_preexec
add-zsh-hook precmd _claw_precmd
