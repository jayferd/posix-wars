#!/bin/bash

FNAME="$1"
HASH="$2"

echo "fork $$" >> /tmp/fork.log
echo "$HASH" > "$FNAME"
sleep 1
bash $0 $@ & bash $0 $@
