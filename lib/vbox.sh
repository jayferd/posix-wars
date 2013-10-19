# vbox copy <name> <local-src> <remote-dest>
vbox-copy() {
  local name="$1"; shift
  local src="$1"; shift
  local dest="$1"; shift

  vbox guestcontrol "$name" cp "$src" "$dest" \
    --username "$MAP_USER" \
    --password "$MAP_PASSWORD"
}

# vbox exec <vmname> <command...>
vbox-exec() {
  local name="$1"; shift

  vbox guestcontrol "$name" execute \
    --image /bin/bash \
    --username "$USER" \
    --password "$PASSWORD" "$@"
}

vbox-start() {
  local name="$1"; shift
}
