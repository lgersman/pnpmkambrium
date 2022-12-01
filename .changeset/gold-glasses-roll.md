---
'@pnpmkambrium/core': patch
---

add generic docker package build support

- if a `.env` file was provided in the docker package it gets read during build and deploy

  - `DOCKER_TOKEN` the token to use for publishing
  - `DOCKER_USER` used for login purposes. use your docker identity/username, your docker account email will not work
    (if not defined the package scope without leading `@` will be used)
  - `DOCKER_REPOSITORY` the docker repository (aka scope/name part of the image)
    (if not defined the package scope without leading `@` will be used)
  - `DOCKER_REGISTRY` can be used to publish to another docker compatible registry

- `pnpm kambrium-make packages/docker/` will make all docker packages
- `pnpm kambrium-make packages/docker/foo/` will build docker package `packages/docker/foo`

- building a docker image results in a `/package/docker/[package]/build-info` file collecting some metadata about the builded image
