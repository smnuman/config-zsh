#!/usr/bin/env zsh

zmodload zsh/datetime

typeset -A ZPROF_START ZPROF_END

zprof_start() {
  ZPROF_START[$1]=$EPOCHREALTIME
}

zprof_end() {
  ZPROF_END[$1]=$EPOCHREALTIME
}

zprof_report() {
  [[ "$ZSH_PROFILE" != "true" ]] && return

  echo ""
  echo "===== ZSH INIT PROFILE ====="

  local total=0 k
  for k in ${(k)ZPROF_START}; do
    local start=${ZPROF_START[$k]}
    local end=${ZPROF_END[$k]:-$EPOCHREALTIME}
    local dur=$(awk "BEGIN {printf \"%.6f\", $end - $start}")
    printf "%-18s %6.2f ms\n" "$k" "$(awk "BEGIN {printf \"%.2f\", $dur * 1000}")"
    total=$(awk "BEGIN {printf \"%.6f\", $total + $dur}")
  done

  echo "----------------------------"
  printf "%-18s %6.2f ms\n" "TOTAL" "$(awk "BEGIN {printf \"%.2f\", $total * 1000}")"
  echo "============================"
  echo ""

  # printf "%-25s %6.2f ms\n" "TOTAL" "$(awk "BEGIN {printf \"%.2f\", $total * 1000}")"
}
