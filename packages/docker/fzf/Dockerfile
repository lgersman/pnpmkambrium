# syntax=docker/dockerfile:1.4

# -------------------------------------
FROM debian:bullseye-slim as builder

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y ca-certificates wget 

RUN cd /usr/local && wget -qO- https://raw.githubusercontent.com/junegunn/fzf/master/install | bash -s -- --bin

# -------------------------------------
# :debug variant provides a shell (busybox sh)
FROM gcr.io/distroless/base-debian11:debug

COPY --from=builder /usr/local/bin/fzf /usr/local/bin/

COPY --chmod=755 ./packages/docker/fzf/entrypoint.sh /usr/local/bin/
COPY ./packages/docker/fzf/README.md /
COPY ./LICENSE.md /

SHELL ["/busybox/sh", "-c"]

ENTRYPOINT ["entrypoint.sh"]

