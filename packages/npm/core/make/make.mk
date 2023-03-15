#
# this is the main pnpmkambrium makefile
# 
# if you want to extend pnpmkambrium with custom make targets simply include this file in your own make file
#

# KAMBRIUM_MAKEFILE_DIR points to the directory where this file was loaded from
KAMBRIUM_MAKEFILE_DIR := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))

export KAMBRIUM_MAKEFILE_DIR
include $(KAMBRIUM_MAKEFILE_DIR)/make-shell.mk 
include $(KAMBRIUM_MAKEFILE_DIR)/make-common.mk
include $(KAMBRIUM_MAKEFILE_DIR)/make-functions.mk
include $(KAMBRIUM_MAKEFILE_DIR)/make-rules.mk
include $(KAMBRIUM_MAKEFILE_DIR)/make-targets.mk
include $(KAMBRIUM_MAKEFILE_DIR)/make-init.mk
include $(KAMBRIUM_MAKEFILE_DIR)/make-lint.mk
include $(KAMBRIUM_MAKEFILE_DIR)/make-clean.mk
include $(KAMBRIUM_MAKEFILE_DIR)/make-docker.mk
include $(KAMBRIUM_MAKEFILE_DIR)/make-wp-plugin.mk
include $(KAMBRIUM_MAKEFILE_DIR)/make-npm.mk
include $(KAMBRIUM_MAKEFILE_DIR)/make-docs.mk
include $(KAMBRIUM_MAKEFILE_DIR)/make-gh-pages.mk
include $(KAMBRIUM_MAKEFILE_DIR)/make-github.mk
include $(KAMBRIUM_MAKEFILE_DIR)/make-help.mk

# ensure required utilities are installed
_ := $(call ensure-commands-exists, node sed git touch jq docker tee awk)

# pnpm env use --global $(grep -oP '(?<=use-node-version=).*' ./.npmrc1)
# node version to use by pnpm (defined in .npmrc)
NODE_VERSION != sed -n '/^use-node-version=/ {s///p;q;}' .npmrc

# path to node binary configured in .npmrc
NODE := $(HOME)/.local/share/pnpm/nodejs/$(NODE_VERSION)/bin/node

# pick up npm scope from package.json name
MONOREPO_SCOPE != jq -r '.name | values' package.json

# always run prettier using ignored files from .lintignore 
PRETTIER := $(PNPM) prettier --ignore-path='$(CURDIR)/.lintignore' --cache --check

# always run eslint using ignored files from .lintignore 
ESLINT := $(PNPM) eslint --ignore-path='$(CURDIR)/.lintignore' --no-error-on-unmatched-pattern

# project (path) specific temp directory outside of the checked out repository
KAMBRIUM_TMPDIR := $(shell mktemp -d --suffix ".pnpmkambrium-$$(basename $(CURDIR))")
# delete all KAMBRIUM_TMPDIR's older than one day
$(shell find $(shell dirname $(KAMBRIUM_TMPDIR)) -maxdepth 0 -ctime +1 -name '*.*.pnpmkambrium-$(shell basename $(CURDIR))' -type d -delete)

# please note the variables in the root .env file need to be exported to take effect
# example : "export foo=bar"
-include .env

# this target triggers pnpm to download/install the required nodejs if not yet available 
$(NODE):
# > @$(PNPM) exec node --version 1&>/dev/null
# > touch -m $@

pnpm-lock.yaml: package.json 
>  $(PNPM) install --lockfile-only
> @touch -m pnpm-lock.yaml

node_modules/: pnpm-lock.yaml 
# pnpm bug: "pnpm use env ..." is actually not needed but postinall npx calls fails
> $(PNPM) env use --global $(NODE_VERSION)
>  $(PNPM) install --frozen-lockfile
> @touch -m node_modules
