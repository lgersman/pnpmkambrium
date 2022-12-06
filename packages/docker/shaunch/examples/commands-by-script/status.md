#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

UNAME_A=`uname -a`

cat <<EOF

# Status

This software is running on a

```
${UNAME_A}
```

system.
EOF
