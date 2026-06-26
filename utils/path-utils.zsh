#!/usr/bin/env zsh
# ~/.config/zsh/utils/path-utils.zsh

rgz() {
    rg "$@" | sed "s|$HOME|~|g"
}
