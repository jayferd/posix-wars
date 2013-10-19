#!/bin/bash

FNAME="$1"
HASH="$2"

while true; do
  ps aux | fgrep "$FNAME" | fgrep -v $$ | awk '{print $2}' | xargs kill -9
  sleep 1
  echo "$HASH" > "$FNAME"
done
