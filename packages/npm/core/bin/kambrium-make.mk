#!/usr/bin/env make -f

# make output less verbose
# MAKEFLAGS += --silent

KAMBRIUM_MAKEFILE_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
include $(KAMBRIUM_MAKEFILE_DIR)/kambrium-make-common.mk

MONOREPO_SCOPE != jq -r '.name | values' package.json

PRETTIER := $(PNPM) prettier --ignore-path='$(shell git rev-parse --show-toplevel)/.lintignore' --cache --check
ESLINT := $(PNPM) eslint --ignore-path='$(shell git rev-parse --show-toplevel)/.lintignore' --no-error-on-unmatched-pattern

# this target triggers pnpm to download/install the required nodejs if not yet available 
$(NODE):
# > @$(PNPM) exec node --version 1&>/dev/null
# > touch -m $@

pnpm-lock.yaml: package.json 
>	$(PNPM) install --lockfile-only
> @touch -m pnpm-lock.yaml

node_modules: pnpm-lock.yaml 
# pnpm bug: "pnpm use env ..." is actually not needed but postinall npx calls fails
> $(PNPM) env use --global $(NODE_VERSION)
>	$(PNPM) install --frozen-lockfile
> @touch -m node_modules

.PHONY: commit
#HELP: * git gz and commit
commit: node_modules
> pnpm nano-staged --allow-empty && PNPM_WORKSPACE_PACKAGES=$$(pnpm list --recursive --filter '@$(MONOREPO_SCOPE)/*' --json | jq -c  '[.[].name | select( . != null )]') pnpm git cz

.PHONY: lint
#HELP: * lint sources
lint: node_modules/
> $(PRETTIER) --ignore-unknown .
> $(ESLINT) .
> ! (command -v $$($(PNPM) bin)/stylelint >/dev/null) || \
> 	$(PNPM) stylelint --ignore-path='$(shell git rev-parse --show-toplevel)/.lintignore' --allow-empty-input ./packages/**/*.{css,scss}

.PHONY: lint-fix
#HELP: * lint sources and fix them where possible
lint-fix: node_modules
> $(PRETTIER) --cache --check --write .
> $(ESLINT) --fix .
> ! (command -v $$($(PNPM) bin)/stylelint >/dev/null) || \
> $(PNPM) stylelint --ignore-path='$(shell git rev-parse --show-toplevel)/.lintignore' --allow-empty-input --fix ./packages/**/*.{css,scss}

# see https://gist.github.com/Olshansk/689fc2dee28a44397c6e31a0776ede30
.PHONY: help
#HELP: * prints this screen
help: 
> @printf "Available targets\n\n"
> @awk '/^[a-zA-Z\-_0-9]+:/ { 
>   helpMessage = match(lastLine, /^#HELP: (.*)/); 
>   if (helpMessage) { 
>     helpCommand = substr($$1, 0, index($$1, ":")-1); 
>     helpMessage = substr(lastLine, RSTART + 6, RLENGTH); 
>     gsub(/\\n/, "\n", helpMessage);
>     printf "\033[36m%-30s\033[0m %s\n", helpCommand, helpMessage;
>   } 
> } 
> { lastLine = $$0 }' $(MAKEFILE_LIST)