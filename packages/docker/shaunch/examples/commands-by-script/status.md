#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

cat <<EOF

# Status

This machine is operated using

**$(uname -a)**

system.
EOF
