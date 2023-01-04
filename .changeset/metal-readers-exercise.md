---
'@pnpmkambrium/core': patch
---

add make debugging support

- environment variable `KAMBRIUM_DEBUG` : print out targets and dependencies before executing if set to true

- environment variable `KAMBRIUM_VERBOSE` : set bash into verbose mode using +x which in turn outputs every executed SHELL statement
