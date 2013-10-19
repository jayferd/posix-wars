#!/bin/bash

set -x

posix-wars::usage() {
cat <<EOF
Here's how you use this lib!
EOF
}

# posix-wars fight <map> <script1> <script2>
posix-wars::fight() {
  local map="$1"; shift
  local script1="$1"; shift
  local script2="$1"; shift

  local vm_name="$(map-setup "$map")"

  (
    . "$map/config"

  )
  local file=
}

# posix-wars modify /path/to/map
posix-wars::modify() {
  local map="$1"; shift

  map-setup "$map"
  local vm_name="$VM_NAME"
  vbox-start "$vm_name" gui
  vbox-wait-for-shutdown "$vm_name"
  vbox-teardown "$vm_name"
}

# posix-wars create-map /path/to/base /path/to/map
posix-wars::create-map() {
  local base="$1"; shift
  local dest="$1"; shift

  if [[ ! -d "$dest" ]]; then
    echo -n "copying..."
    cp -r "$base" "$dest"
    echo "done."
  fi

  posix-wars modify "$dest"
}
