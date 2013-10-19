#!/bin/bash

set -x

# vbox copy <name> <local-src> <remote-dest>
vbox() {
  if [[ -z "$VBOXMANAGE" ]]; then
    VBOXMANAGE=VBoxManage
    exists "$VBOXMANAGE" || die 'cannot find VBoxManage'
  fi

  "$VBOXMANAGE" "$@"
}

# vbox-copy <vmname> <src> <dest>
vbox-copy() {
  local name="$1"; shift
  local src="$1"; shift
  local dest="$1"; shift

  vbox guestcontrol "$name" cp "$src" "$dest" \
    --username "$MAP_USER" \
    --password "$MAP_PASSWORD"
}

# vbox-exec <vmname> <command...>
vbox-exec() {
  local name="$1"; shift

  vbox guestcontrol "$name" execute \
    --image /bin/bash \
    --username "$MAP_USER" \
    --password "$MAP_PASSWORD" "$@"
}

# vbox-start <vmname> gui|sdl|headless
vbox-start() {
  local name="$1"; shift
  local mode="$1"; shift
  vbox startvm "$name" --type "$mode"
}

map-setup() {
  local map="$1"
  local map_name="$(basename "$map")"
  local vm_name="$map_name".$$
  local bus_name="${vm_name}_bus"

  vbox createvm --name "$vm_name" --register
  vbox storagectl "$vm_name" --name "$bus_name" --add sata
  vbox storageattach "$vm_name" \
    --storagectl "$bus_name" \
    --port 0 --device 0 \
    --type hdd \
    --medium "$map/disk.vdi"

  VM_NAME="$vm_name"
}

vbox-is-running() {
  local vm_name="$1"

  vbox list runningvms | fgrep -q "$vm_name"
}

vbox-wait-for-shutdown() {
  echo -n "waiting for $1 to shut down..."
  while vbox-is-running "$1"; do
    sleep 2
  done
  echo "done."
}

vbox-teardown() {
  local vm_name="$1"
  vbox unregistervm "$vm_name"
}
