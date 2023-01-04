---
'@pnpmkambrium/core': patch
---

add generic gh-pages package build support

- if a `.env` file was provided in the npm package it gets read during build and deploy

- `make gh-pages-push-gh-foo` will update/deploy branch `gh-pages` with the contents of sub package `packages/docs/foo`'s `build` folder and push it back to the git repositories `origin`
