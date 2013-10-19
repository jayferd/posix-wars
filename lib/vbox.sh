#!/bin/bash

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
    --password "$MAP_PASSWORD" || die "copy failed!"
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

vbox-kill() {
  local vm_name="$1"; shift
  vbox controlvm "$vm_name" poweroff
}

vbox-cat-file() {
  if [[ "$GUI" -eq 1 ]]; then
    local mode=gui
  else
    local mode=headless
  fi

  local disk="$1"; shift
  local target="$1";

  local vm_name="referee.$$"
  local bus_name="${vm_name}_bus"

  vbox createvm --name "$vm_name" --register
  vbox storagectl "$vm_name" --name "$bus_name" --add sata
  vbox storageattach "$vm_name" \
    --storagectl "$bus_name" \
    --port 0 --device 0 \
    --type hdd \
    --medium "$LIB_DIR/../share/maps/base/disk.vdi"
  vbox-start "$vm_name" "$mode"
  vbox-wait-for-startup "$vm_name"
  vbox storageattach "$vm_name" \
    --storagectl "$bus_name" \
    --port 1 --device 0 \
    --type hdd \
    --medium "$disk"
  sleep 2 # HACK
  vbox-exec "$vm_name" --wait-exit -- -c "mount -t ext4 /dev/sdb1 /mnt/arena"

  RESULT="$(vbox-exec "$vm_name" --wait-stdout -- -c "cat /mnt/arena/$target")"

  if [[ ! $? -eq 0 ]]; then
    RESULT=''
  fi

  [[ "$GUI" -eq 1 ]] || vbox-kill "$vm_name"
  vbox-teardown "$vm_name"
}

vbox-copy-disk() {
  local src="$1"; shift
  local dest="$1"; shift

  vbox clonehd "$src" "$dest"
}

map-setup() {
  local map="$1"; shift
  local disk="$1"
  if [[ ! -e "$map/$disk" ]]; then
    echo -n "creating arena $map/$disk..."
    vbox-copy-disk "$map/disk.vdi" "$map/$disk"
    echo "done."
  fi

  local map_name="$(basename "$map")"
  local vm_name="$map_name".$$
  local bus_name="${vm_name}_bus"

  vbox createvm --name "$vm_name" --register
  vbox storagectl "$vm_name" --name "$bus_name" --add sata
  vbox storageattach "$vm_name" \
    --storagectl "$bus_name" \
    --port 0 --device 0 \
    --type hdd \
    --medium "$map/$disk"

  VM_NAME="$vm_name"
}

vbox-is-running() {
  local vm_name="$1"

  vbox list runningvms | fgrep -q "$vm_name"
}

vbox-is-booted() {
  local vm_name="$1"
  vbox guestproperty get "$vm_name" /VirtualBox/GuestInfo/OS/Version | fgrep -q Value:
}

vbox-wait-for-startup() {
  while ! vbox-is-booted "$@"; do
    sleep 2
  done
}

vbox-teardown() {
  local vm_name="$1"

  echo -n "waiting for $vm_name to shut down..."
  while ! vbox unregistervm "$vm_name" 2>/dev/null; do
    sleep 2
  done
  echo "done."
}
