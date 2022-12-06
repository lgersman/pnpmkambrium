#!/usr/bin/env bash

# ensure backup drive mounted

cat <<EOF

backup drive mounted

Press any key to continue ...
EOF

read  -n 1

# restart shaunch
$SHAUNCH_COMMAND