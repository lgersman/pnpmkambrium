---
'@pnpmkambrium/core': patch
---

add make debugging support

- environment variable `KAMBRIUM_TRACE` : print out targets and dependencies before executing if set to true

  - if you use make version > 4 you could use alternatively make option `--trace` (see https://lists.gnu.org/archive/html/make-w32/2013-10/msg00021.html)
