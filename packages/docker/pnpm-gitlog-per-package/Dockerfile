# syntax=docker/dockerfile:1.4

FROM bitnami/minideb:bullseye
#pnpm-gitlog-per-package   1.0.0     b59cf557a688   2 seconds ago   171MB
SHELL ["/bin/bash", "-c"]

RUN install_packages  \
  git \
  curl \
  fzf

RUN curl -fsSL https://get.pnpm.io/install.sh | $SHELL -


# FROM debian:bullseye-slim
# pnpm-gitlog-per-package   1.0.0     06131e402472   1 second ago   267MB
# SHELL ["/bin/bash", "-c"]

# RUN apt-get update \
#   && DEBIAN_FRONTEND=noninteractive apt-get install -y \
#   git \
#   curl \
#   fzf \
#   && apt-get clean \
#   && rm -rf /var/lib/apt/lists/*

# RUN curl -fsSL https://get.pnpm.io/install.sh | $SHELL -

# FROM bitnami/minideb:jessie
# # only 50mb !
# RUN install_packages python
# # see https://github.com/bitnami/minideb

# ARG nodejs_base
# FROM node:${nodejs_base}

# COPY ./docker/README.md /
# COPY ./LICENSE.md /

# COPY --chown=node:node ./docker/*.tgz /tmp/

# RUN npm config set update-notifier false && NODE_ENV=production ls /tmp/*.tgz | xargs npm install -g --no-fund --silent --omit=peer --omit=optional --omit=dev && rm /tmp/*.tgz
# COPY --chown=node:node --chmod=755 ./docker/entrypoint.sh /usr/local/bin/ 
# RUN ls -la /usr/local/bin/entrypoint.sh

# USER node
# ENTRYPOINT  [ "entrypoint.sh"]