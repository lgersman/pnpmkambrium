# syntax=docker/dockerfile:1.4

# @TODO: dockerize using distroless go:debug

# FROM node:latest
# SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# ENV DEBIAN_FRONTEND=noninteractive

# RUN apt update && \
#   apt install -y git \
#   ca-certificates \
#   jq \
#   wget && \
#   rm -rf /var/lib/apt/lists/*

# RUN cd /usr/local && wget -qO- https://raw.githubusercontent.com/junegunn/fzf/master/install | $SHELL -s -- --bin

# COPY ./packages/docker/shaunch/README.md /
# COPY ./LICENSE.md /
# COPY --chown=node:node --chmod=755 ./packages/docker/shaunch/bin/shaunch.sh /usr/local/bin/
# COPY --chown=node:node --chmod=755 ./packages/docker/shaunch/entrypoint.sh /usr/local/bin/

# RUN npm config set update-notifier false && npm install --no-fund --silent -g pnpm

# USER node

# ENTRYPOINT ["entrypoint.sh"]