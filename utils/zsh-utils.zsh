#!/usr/bin/env zsh
# search and display aliases matching a pattern
# usage: laa [pattern] [width]
# example: laa g 20
laa() {
    local p=${1:-l} w=${2:-18}
    alias \
    | command grep -v "^laa=" \
    | command grep "^${(q)p}[^=]*=" --color=always \
    | sort \
    | awk -F= -v ww="$w" '{ printf "%-"ww"s = %s\n", $1, substr($0, index($0, "=")+1) }'
}

# check if a directory is in PATH
# usage: path_has <directory>
# example: path_has "$HOME/bin"
path_has() {
  [[ ":$PATH:" == *":$1:"* ]] && { echo "Hurray! I am already in path!!"; return 0; } || { echo "!! not found"; return 1; }
}

path_has1() {
  local v=0; [[ "$1" == "-v" ]] && { v=1; shift; }
  (( $# == 0 )) && { echo "What are you looking for?"; return 2; }
  local dir="$~1"
  local showdir="%F{cyan}${dir/#\~/$HOME}%f"
  [[ ":$PATH:" == *:${~1}:* ]] \
        && { (( v )) && print -P "Hurray! '$showdir' is already in PATH"; return 0; } \
        || { (( v )) && print -P "!! '$showdir' not found in PATH"; return 1; }
}

path_has2() {
  local v=0
  [[ $1 == -v ]] && shift && v=1
  (( $# == 0 )) && { (( v )) && echo "What are you looking for?"; return 2 }

  [[ ":$PATH:" == *:${~1}:* ]] \
    && { (( v )) && echo "Matched PATH entry: $1"; return 0 } \
    || { (( v )) && echo "No PATH entry matches: $1"; return 1 }
}

# path_has3() {
#   setopt localoptions noglob

#   local v=0
#   [[ $1 == "-v" ]] && shift && v=1
#   [[ -z $1 ]] && { (( v )) && echo "What are you looking for?"; return 2 }

#   local -a matches
#   matches=( ${(M)${(s.:.)PATH}:${~1}} )

#   if [[ ${#matches} -gt 0 ]]; then
#     (( v )) && print -rl -- "Matched PATH entries:" $matches
#     return 0
#   else
#     (( v )) && echo "No PATH entry matches: $1"
#     return 1
#   fi
# }

# path_has3() {
#   setopt localoptions noglob

#   local v=0
#   [[ $1 == -v ]] && shift && v=1
#   [[ -z $1 ]] && { [[ $v == 1 ]] && echo "What are you looking for?"; return 2 }

#   local -a matches split_path
#   split_path=( ${(s.:.)PATH} )
#   matches=( ${(M)${split_path}:${(q)~1}} )

#   if [[ ${#matches} -gt 0 ]]; then
#     [[ $v == 1 ]] && print -rl -- "Matched PATH entries:" $matches
#     return 0
#   else
#     [[ $v == 1 ]] && echo "No PATH entry matches: $1"
#     return 1
#   fi
# }


path_has3() {
    setopt localoptions noglob extendedglob

    local verbose=0
    [[ $1 == -v ]] && { verbose=1; shift; }

    [[ -z $1 ]] && {
        (( verbose )) && echo "Usage: path_has3 [-v] <directory-or-pattern>"
        return 2
    }

    local -a split_path matches
    split_path=( ${(s.:.)PATH} )

    # The actual fix: better pattern matching in $PATH
    matches=( ${(M)split_path:#${(q)~1}} )

    # Alternative (often cleaner) way — pick one:
    # matches=( ${(M)split_path:#${1}} )          # literal match (most common need)
    # matches=( ${(M)split_path:#${(q)~1}} )      # quoted/escaped match
    # matches=( ${(M)split_path:#*${(q)~1}*} )    # contains substring

    if [[ ${#matches} > 0 ]]; then
        (( verbose )) && {
            print -r -- "Found in PATH:"
            print -rl -- $matches
        }
        return 0
    else
        (( verbose )) && print -r -- "Not found in PATH: $1"
        return 1
    fi
}
