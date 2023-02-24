# syntax=docker/dockerfile:1.4

# @TODO: dockerize using distroless go:debug

FROM debian:bullseye-slim
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && \
  apt install -y git \
  ca-certificates \
  jq \
  binutils \
  wget && \
  rm -rf /var/lib/apt/lists/*

RUN cd /usr/local && wget -qO- https://raw.githubusercontent.com/junegunn/fzf/master/install | $SHELL -s -- --bin

# environment variable acts as marker for shaunch to detect if running inside a docker container
ENV SHAUNCH_DOCKERIZED=true

# see https://github.com/nodejs/docker-node/blob/9220863a62a5f9d76bb761d1e385674de39224a6/19/bullseye/Dockerfile#L3
RUN groupadd --gid 1000 node \
  && useradd --uid 1000 --gid node --shell /bin/bash --create-home node

COPY ./packages/docker/shaunch/README.md /
COPY ./LICENSE.md /
COPY --chown=node:node --chmod=755 ./packages/docker/shaunch/bin/shaunch.sh /usr/local/bin/
COPY --chown=node:node --chmod=755 ./packages/docker/shaunch/entrypoint.sh /usr/local/bin/

USER node

ENTRYPOINT ["entrypoint.sh"]