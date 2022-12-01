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

@TODO:
