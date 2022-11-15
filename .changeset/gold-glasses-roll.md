---
'@pnpm-kambrium/core': patch
---

add generic docker package build support

- @TODO: document all possible settings derived from root `package.json`

- if a `.env` file was provided in the docker package it gets read during make targets buildinf and deploying docker images

  - @TODO: document all possible settings

- `pnpm make packages/docker/` will make all docker packages
- `pnpm make packages/docker/foo/` will build docker package `packages/docker/foo`

- building a docker image results in a `/package/docker/[package]/build-info` file collecting some metadata about the builded image
