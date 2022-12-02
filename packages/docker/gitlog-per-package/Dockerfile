# syntax=docker/dockerfile:1.4

FROM bitnami/node:18
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN install_packages  \
  git \
  jq \
  wget

RUN cd /usr/local && wget -qO- https://raw.githubusercontent.com/junegunn/fzf/master/install | $SHELL -s -- --bin

# see https://github.com/nodejs/docker-node/blob/9220863a62a5f9d76bb761d1e385674de39224a6/19/bullseye/Dockerfile#L3
RUN groupadd --gid 1000 node \
  && useradd --uid 1000 --gid node --shell /bin/bash --create-home node

COPY ./packages/docker/gitlog-per-package/README.md /
COPY ./LICENSE.md /
COPY --chown=node:node --chmod=755 ./packages/docker/gitlog-per-package/bin/gitlog-per-package.sh /usr/local/bin/
COPY --chown=node:node --chmod=755 ./packages/docker/gitlog-per-package/entrypoint.sh /usr/local/bin/

RUN npm config set update-notifier false && npm install --no-fund --silent -g pnpm

USER node

ENTRYPOINT ["entrypoint.sh"]
