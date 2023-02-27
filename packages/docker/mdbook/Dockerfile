# syntax=docker/dockerfile:1.4

#FROM gcr.io/distroless/cc:debug
FROM debian:bullseye-slim

ARG MDBOOK_VERSION="0.4.25"
ADD --chmod=755 https://github.com/rust-lang/mdBook/releases/download/v${MDBOOK_VERSION}/mdbook-v${MDBOOK_VERSION}-x86_64-unknown-linux-musl.tar.gz /tmp/

ARG MDBOOK_MERMAID_VERSION="0.12.6"
ADD --chmod=755 https://github.com/badboy/mdbook-mermaid/releases/download/v${MDBOOK_MERMAID_VERSION}/mdbook-mermaid-v${MDBOOK_MERMAID_VERSION}-x86_64-unknown-linux-musl.tar.gz /tmp/

ARG MDBOOK_TOC_VERSION="0.11.0"
ADD --chmod=755 https://github.com/badboy/mdbook-toc/releases/download/${MDBOOK_TOC_VERSION}/mdbook-toc-${MDBOOK_TOC_VERSION}-x86_64-unknown-linux-musl.tar.gz /tmp/
RUN cd /usr/local/bin && ls /tmp/*.tar.gz | xargs -i tar xfz {} && rm /tmp/*.tar.gz

ARG MDBOOK_PRESENTATION_PREPROCESSOR_VERSION="0.2.0"
ADD --chmod=755 https://github.com/FreeMasen/mdbook-presentation-preprocessor/releases/download/v${MDBOOK_PRESENTATION_PREPROCESSOR_VERSION}/mdbook-presentation-preprocessor-Linux.zip /tmp/
RUN apt-get update && apt-get install -y --no-install-recommends unzip && \
  cd /usr/local/bin && ls /tmp/*.zip | xargs -i unzip {} && \
  apt-get remove --purge -y unzip && rm -rf /var/lib/apt/lists/* && \
  rm /tmp/*.zip


COPY ./README.md /

# ADD https://raw.githubusercontent.com/rust-lang/mdBook/master/LICENSE /
# ADD doesnt work nicely with illegal eTags thats why we do it using wget
RUN apt update && apt install -y wget && rm -rf /var/lib/apt/lists/*
RUN wget https://raw.githubusercontent.com/rust-lang/mdBook/master/LICENSE -directory-prefix=/


# WORKDIR /data

COPY --chmod=755 ./packages/docker/mdbook/entrypoint.sh /usr/local/bin/

LABEL "mdbook.version"=$MDBOOK_VERSION
LABEL "mdbook-mermaid.version"=$MDBOOK_MERMAID_VERSION
LABEL "mdbook-toc.version"=$MDBOOK_TOC_VERSION
LABEL "mdbook-presentation-preprocessor.version"=$MDBOOK_PRESENTATION_PREPROCESSOR_VERSION

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# FROM rust:latest as builder

# # see https://github.com/hrektts/docker-mdbook/blob/master/Dockerfile
# ARG MDBOOK_VERSION="0.4.21"

# RUN cargo install mdbook --vers ${MDBOOK_VERSION}

# # https://fnordig.de/2019/07/11/mdbook-toc-and-mermaid-preprocessors/
# RUN cargo install mdbook-toc mdbook-mermaid

# FROM debian:bullseye-slim

# COPY --from=builder /usr/local/cargo/bin/mdbook* /usr/local/bin/

# COPY ./README.md /
# ADD https://raw.githubusercontent.com/rust-lang/mdBook/master/LICENSE /

# LABEL mdbook_version=$MDBOOK_VERSION

# WORKDIR /data

# COPY --chmod=755 ./packages/docker/mdbook/entrypoint.sh /usr/local/bin/

# ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]