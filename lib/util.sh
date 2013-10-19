#!/bin/bash

die() {
  echo "$@" >&2
  exit 1
}

exists() {
  type "$@" &>/dev/null
}

vbox() {
  if [[ -z "$VBOXMANAGE" ]]; then
    VBOXMANAGE=VBoxManage
    exists "$VBOXMANAGE" || die 'cannot find VBoxManage'
  fi

  "$VBOXMANAGE" "$@"
}

random-hash() {
  local seed="$@"

  echo $$.$RANDOM."$seed" | md5sum | cut -d' ' -f1
}

posix-wars() {
  case "$1" in
    -?|-h|--help)
      posix-wars::usage
    ;;
    *)
      if exists posix-wars::"$1"; then
        posix-wars::"$1" "$@"
      fi
    ;;
  esac
}
