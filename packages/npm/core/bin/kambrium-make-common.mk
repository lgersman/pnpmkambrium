# ensure make is supporting .RECIPEPREFIX
ifeq ($(origin .RECIPEPREFIX), undefined)
  $(error This Make does not support .RECIPEPREFIX. Please use GNU Make 4.0 or later)
endif
# make to use > as the block character
.RECIPEPREFIX = >

# alwas use bash as shell (to get <<< and stuff working), otherwise sh would be used by default
SHELL != which bash
# use bash strict mode o that make will fail if a bash statement fails
.SHELLFLAGS := -eu -o pipefail -c
# debug make shell execution
#.SHELLFLAGS += -vx

# disable default rules enabled by default (build yacc, cc and stuff)
MAKEFLAGS += --no-builtin-rules 
# warn if unused variables in use
MAKEFLAGS += --warn-undefined-variables
# # suppress "make[2]: Entering directory" messages
# MAKEFLAGS += --no-print-directory

# always execute targets as a single shell script (i.e. : not line by line) 
.ONESHELL:

.DEFAULT_GOAL := help
# --

# ensure pnpm is available
ifeq (,$(shell which pnpm))
	define PNPM_NOT_FOUND
pnpm is not installed or not in PATH. 
Install it using "wget -qO- 'https://get.pnpm.io/install.sh' | sh -"
(windows : 'iwr https://get.pnpm.io/install.ps1 -useb | iex') 

See more here : https://docs.npmjs.com/getting-started/installing-node 
	endef
	$(error $(PNPM_NOT_FOUND))
endif

# ensure a recent nodejs version is available
ifeq (,$(shell which nodejs))
	define NODEJS_NOT_FOUND
node is not installed or not in PATH. 
See more here : https://nodejs.org/en/download/ 
	endef
	$(error $(NODEJS_NOT_FOUND))
endif

PNPM != which pnpm
# disable PNPM update notifier
# export NO_UPDATE_NOTIFIER=1

NODE_VERSION != sed -n '/^use-node-version=/ {s///p;q;}' .npmrc
NODE := $(HOME)/.local/share/pnpm/nodejs/$(NODE_VERSION)/bin/node 