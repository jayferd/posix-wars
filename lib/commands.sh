#!/bin/bash

set -x

posix-wars::usage() {
cat <<EOF
posix-wars fight <mapdir> <script1> <script2>
posix-wars modify <mapdir>
posix-wars create-map <basemapdir> <newmapdir>
EOF
}

# posix-wars fight <map> <script1> <script2>
posix-wars::fight() {
  local map=
  local script1=
  local script2=

  local disk="disk.$$.vdi"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -m|--map) local map="$2"; shift ;;
      -g|--gui) local GUI=1 ;;
      *)
        if [[ -z "$script1" ]]; then
          local script1="$1"
        else
          local script2="$1"
        fi
      ;;
    esac

    shift
  done

  if [[ "$(( $RANDOM % 2 ))" -eq 0 ]]; then
    tmp="$script1"
    script1="$script2"
    script2="$tmp"
  fi

  map-setup "$map" "disk.$$.vdi"
  local vm_name="$VM_NAME"

  local hash1="$(random-hash 1)"
  local hash2="$(random-hash 2)"

  vbox-start "$vm_name" headless
  vbox-wait-for-startup "$vm_name"

  (
    . "$map/config"
    local dest1="$MAP_SCRIPT_LOCATION/script1.sh"
    local dest2="$MAP_SCRIPT_LOCATION/script2.sh"

    MAP_TARGET_FILE="$(tr -d '\r' <<<"$MAP_TARGET_FILE")"

    echo "($script1) -> ($dest1)"
    echo "($script2) -> ($dest2)"

    vbox-copy "$vm_name" "$script1" "$dest1"
    vbox-copy "$vm_name" "$script2" "$dest2"
    echo "bash '$dest1' '$MAP_TARGET_FILE' $hash1 & bash '$dest2' '$MAP_TARGET_FILE' $hash2 &"
    vbox-exec "$vm_name" -- -c \
      "bash '$dest1' '$MAP_TARGET_FILE' $hash1 & bash '$dest2' '$MAP_TARGET_FILE' $hash2 &"

    echo "waiting..."
    sleep "$MAP_WAIT_TIME"
    vbox-kill "$vm_name"
    sleep 2 # HACK
    vbox-teardown "$vm_name"

    vbox-cat-file "$map/$disk" "$MAP_TARGET_FILE"

    if [[ -z "$RESULT" ]]; then
      echo "DRAW: Error reading the target file or empty target file"
    elif [[ "$RESULT" = "$hash1" ]]; then
      echo "WINNER: $script1"
    elif [[ "$RESULT" = "$hash2" ]]; then
      echo "WINNER: $script2"
    else
      echo "DRAW: file contained $RESULT"
    fi

    rm "$map/$disk"
  )
}

# posix-wars modify /path/to/map
posix-wars::modify() {
  local map="$1"; shift

  map-setup "$map" "disk.vdi"
  local vm_name="$VM_NAME"
  vbox-start "$vm_name" gui
  vbox-teardown "$vm_name"
}

# posix-wars create-map /path/to/base /path/to/map
posix-wars::create-map() {
  local src="$1"; shift
  local dest="$1"; shift

  if [[ ! -d "$dest" ]]; then
    echo -n "copying..."
    mkdir "$dest"
    cp "$src/config" "$dest/config"
    vbox-copy-disk "$src/disk.vdi" "$dest/disk.vdi"
    echo "done."
  fi

  posix-wars modify "$dest"
}
