#!/bin/bash

die() {
  echo "$@" >&2
  exit 1
}

exists() {
  type "$@" &>/dev/null
}

random-hash() {
  local seed="$@"

  echo $$.$RANDOM."$seed" | md5sum | cut -d' ' -f1
}
