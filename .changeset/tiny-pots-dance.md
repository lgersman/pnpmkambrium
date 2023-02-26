---
'@pnpmkambrium/core': patch
---

build chain template support

any executable \*.kambrium-template file within the monospace will be executed in packages build tasks to support template based file generation.

example: executable packages/foo/src/bar.js.kambrium-template will be automatically executed and its output saved to packages/foo/src/bar.js
