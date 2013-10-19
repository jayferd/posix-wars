#!/bin/bash

set +o xtrace

. "$LIB_DIR/util.sh"
. "$LIB_DIR/vbox.sh"
. "$LIB_DIR/commands.sh"

posix-wars() {
  case "$1" in
    -?|-h|--help)
      posix-wars::usage
    ;;
    *)
      if exists posix-wars::"$1"; then
        local cmd="$1"; shift
        posix-wars::"$cmd" "$@"
      fi
    ;;
  esac
}
