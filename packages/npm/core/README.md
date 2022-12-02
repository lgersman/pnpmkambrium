<!-- % SNOWPLOUGH(1)
% Jérôme Belleman
% June 2013 -->

# Purpose

@TODO:

# How it works

# Configuration

# Directory layout

# Usage

Calling `pnpm kambrium-make` will show the available targets

## Configuration

## docker packages

- deploy/push docker image

  Deploying a docker image to a Docker registry like Docker Hub requires at least a docker access token.
  The [access token](https://docs.docker.com/docker-hub/access-tokens/) can be provided using a `.env` file or as environment variable.

  Examples :

  - `DOCKER_TOKEN=xxx pnpm kambrium-make packages/docker/` will deploy all docker sub packages to the default registry (Docker Hub)

  - `DOCKER_TOKEN=xxx pnpm kambrium-make packages/docker/foo/` will deploy docker sub package `packages/docker/foo/`

Execute `pnpm kambrium-make` for more docker related targets.

## npm packages

- deploy/push npm package

  Deploying a npm package to a NPM registry like [npmjs](https://www.npmjs.com/) requires at least a npm access token.
  The [access token](https://docs.npmjs.com/creating-and-viewing-access-tokens#creating-tokens-on-the-website) can be provided using a `.env` file or as environment variable.

  Examples :

  - `NPM_TOKEN=xxx pnpm kambrium-make packages/npm/` will deploy all docker sub packages to the default registry (Docker Hub)

  - `NPM_TOKEN=xxx pnpm kambrium-make packages/npm/foo/` will deploy npm sub package `packages/npm/foo/`

Execute `pnpm kambrium-make` for more docker related targets.

# Caveats

- You made changes in your sub package but `pnpm kambrium-make ...` does not rebuild/thinks nothing has changed

  Your can workaround this issue by simply force rebuilding the package using `pnpm kambrium-make -B ...`

- Don't use minus (`-`) sign in docker sub package scopes

  Suppose you have a sub package `/packages/docker/bar` named `@my-foo/bar`.

  `pnpm kambrium-make docker-build-bar` and `pnpm kambrium-make docker-push-bar` will derive the `DOCKER_USER` environment variable from scope (package scope="`@my-foo`", derived DOCKER_USER="`my-foo`") by default.

  Unfortunately Docker usernames are prohibited to contain the minus (`-`) sign. _NPM package names in contrast allow minus (`-`) sign in package scopes._

  Either remove the minus (`-`) sign from the sub package scope or set environment variable `DOCKER_USER` (using an `.env` file or at commandline) to the desired docker user.
