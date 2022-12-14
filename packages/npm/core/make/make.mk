# KAMBRIUM_MAKEFILE_DIR points to the directory where this file was loaded from
KAMBRIUM_MAKEFILE_DIR := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))
include $(KAMBRIUM_MAKEFILE_DIR)/make-common.mk
include $(KAMBRIUM_MAKEFILE_DIR)/make-functions.mk
include $(KAMBRIUM_MAKEFILE_DIR)/make-rules.mk
include $(KAMBRIUM_MAKEFILE_DIR)/make-docker.mk
include $(KAMBRIUM_MAKEFILE_DIR)/make-npm.mk
include $(KAMBRIUM_MAKEFILE_DIR)/make-docs.mk
include $(KAMBRIUM_MAKEFILE_DIR)/make-gh-pages.mk
include $(KAMBRIUM_MAKEFILE_DIR)/make-github.mk
include $(KAMBRIUM_MAKEFILE_DIR)/make-targets.mk

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

-include .env

# this target triggers pnpm to download/install the required nodejs if not yet available 
$(NODE):
# > @$(PNPM) exec node --version 1&>/dev/null
# > touch -m $@

pnpm-lock.yaml: package.json 
>	$(PNPM) install --lockfile-only
> @touch -m pnpm-lock.yaml

node_modules/: pnpm-lock.yaml 
# pnpm bug: "pnpm use env ..." is actually not needed but postinall npx calls fails
> $(PNPM) env use --global $(NODE_VERSION)
>	$(PNPM) install --frozen-lockfile
> @touch -m node_modules

.PHONY: lint
#HELP: *  lint sources
lint: node_modules/
> pnpm run -r --if-present lint
> $(PRETTIER) --ignore-unknown .
> $(ESLINT) .
> ! (command -v $$($(PNPM) bin)/stylelint >/dev/null) || \
> 	$(PNPM) stylelint --ignore-path='$(CURDIR)/.lintignore' --allow-empty-input ./packages/**/*.{css,scss}

.PHONY: lint-fix
#HELP: *  lint sources and fix them where possible
lint-fix: node_modules/
> pnpm run -r --if-present lint-fix
> $(PRETTIER) --cache --check --write .
> $(ESLINT) --fix .
> ! (command -v $$($(PNPM) bin)/stylelint >/dev/null) || \
> $(PNPM) stylelint --ignore-path='$(CURDIR)/.lintignore' --allow-empty-input --fix ./packages/**/*.{css,scss}

.PHONY: clean
#HELP: *  clean up intermediate files
clean:
# remove everything matching .gitignore entries (-f is force, you can add -q to suppress command output, exclude node_modules and node_modules/**)
#   => If an untracked directory is managed by a different git repository, it is not removed by default. Use -f option twice if you really want to remove such a directory.
> git clean -Xfd -e '!.env' -e '!/*.code-workspace' -e '!**/node_modules' -e '!**/node_modules/**' -e '!**/.pnpm-store' -e '!**/pnpm-store/**' 
# remove temporary files outside repo
> rm -rf -- $$(dirname $(KAMBRIUM_TMPDIR))/*.pnpmkambrium-$$(basename $(CURDIR))

# delete all files in the current directory (or created by this makefile) that are created by configuring or building the program.
# see https://www.gnu.org/software/make/manual/html_node/Standard-Targets.html 
.PHONY: distclean
#HELP: cleanup node_modules, package-lock.json and docker container/images\n\tATTENTION: You have to call 'make node_modules/' afterwards to make your environment again work properly
distclean: clean
> git clean -Xfd -e '!/*.env' -e '!/*.code-workspace'
> rm -f pnpm-lock.yaml
# remove built docker images
> docker image rm -f $$(docker images -q $(MONOREPO_SCOPE)/*) 2>/dev/null ||:
# clean up unused containers. Container, networks, images, and the build cache
# > docker system prune -a
# remove unused volumes
# > docker volumes prune

# see https://gist.github.com/Olshansk/689fc2dee28a44397c6e31a0776ede30
# @TODO: sort targets alphabetically and primary targets first
.PHONY: help
#HELP: *  prints this screen
help: 
> @printf "Available targets\n\n"
> @awk '/^[a-zA-Z\-_0-9%\/]+:/ { 
>   helpMessage = match(lastLine, /^#HELP: (.*)/); 
>   if (helpMessage) { 
>     helpCommand = substr($$1, 0, index($$1, ":")-1); 
>     helpMessage = substr(lastLine, RSTART + 6, RLENGTH); 
>     gsub(/\\n/, "\n", helpMessage);
>     gsub(/\\t/, "\t", helpMessage);
>     printf "\033[36m%-30s\033[0m %s\n", helpCommand, helpMessage;
>   } 
> } 
> { lastLine = $$0 }' $(MAKEFILE_LIST)

# print out targets and dependencies before executing if environment variable KAMBRIUM_TRACE is set to true
ifeq ($(KAMBRIUM_TRACE),true)
	# see https://www.cmcrossroads.com/article/tracing-rule-execution-gnu-make
	OLD_SHELL := $(SHELL)
	SHELL = $(warning $(TERMINAL_YELLOW)Building $@$(if $<, (from $<))$(if $?, ($? newer))$(TERMINAL_RESET))$(OLD_SHELL)
endif


