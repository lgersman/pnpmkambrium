---
'@pnpmkambrium/core': patch
---

add generic npm package build support

- if a `.env` file was provided in the npm package it gets read during build and deploy

  - `NPM_TOKEN` the token to use for publishing
  - `NPM_REGISTRY` the npm registroy to deploy tos

- `pnpm kambrium-make packages/npm/` will build all npm packages
- `pnpm kambrium-make packages/npm/foo/` will build npm package `packages/npm/foo`

- building a npm package results in a `/package/npm/[package]/build-info` file collecting some metadata about the builded package
