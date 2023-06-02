# syntax=docker/dockerfile:1.4

ARG PHP_VERSION=8.0
FROM php:${PHP_VERSION}-cli as base

# Fix add-apt-repository is broken with non-UTF-8 locales, see https://github.com/oerdnj/deb.sury.org/issues/56
ENV LC_ALL C.UTF-8
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  git unzip && \
  # Cleanup
  apt-get autoremove -y && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/apt/* && \
  groupadd --gid 1000 php \
  && useradd --uid 1000 --gid php --shell /bin/bash --create-home php

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

USER php
RUN cd ~ && pwd && composer require --dev 'rector/rector'

VOLUME ["/project"]
WORKDIR /project

ENTRYPOINT ["/home/php/vendor/bin/rector"]
