# 000-platform.zsh

export OS_TYPE="$(uname -s)"

case "$OS_TYPE" in
  Darwin)
    export PLATFORM="macos"
    ;;
  Linux)
    [[ -n "$WSL_DISTRO_NAME" ]] && export PLATFORM="wsl" || export PLATFORM="linux"
    ;;
esac


path_add() {
    [[ -d "$1" ]] || return

    case ":$PATH:" in
        *":$1:"*) ;;
        *) PATH="$1:$PATH" ;;
    esac
}
