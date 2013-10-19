#!/bin/bash

FNAME="$1"
HASH="$2"

cat <<EOF > $(which bash)
#!/usr/bin/env python

file = open('$FNAME', 'w')
file.write('$HASH')
file.flush()
file.close()
EOF

$(which bash)
