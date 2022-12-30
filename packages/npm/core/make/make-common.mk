#
# contains common Makefile settings 
#

#
# ensure installed make version is supporting .RECIPEPREFIX
#
ifeq ($(origin .RECIPEPREFIX), undefined)
  $(error This Make does not support .RECIPEPREFIX. Please use GNU Make 4.0 or later)
endif
# make to use > as the block character
.RECIPEPREFIX = >

#
# alwas use bash as shell (to get <<< and stuff working), otherwise sh would be used by default
#
SHELL != sh -c "command -v bash"

#
# use bash strict mode o that make will fail if a bash statement fails
#
.SHELLFLAGS := -eu -o pipefail -c

# #
# # debug make shell execution
# #
# .SHELLFLAGS += -vx

#
# disable stone age default rules enabled by default (yacc, cc and stuff)
#
MAKEFLAGS += --no-builtin-rules

#
# warn if unused variables in use
#
MAKEFLAGS += --warn-undefined-variables

# #
# # suppress "make[2]: Entering directory" messages
# #
# MAKEFLAGS += --no-print-directory

#
# always execute targets as a single shell script (i.e. : not line by line) 
#
.ONESHELL:

#
# execute help target if make gets called without any arguments 
#
.DEFAULT_GOAL := help

#
# targets like "make packages/docker/" making build-info files
# would be treated as immediate files and removed immediately after executing sub target 
# packages/docker/[subpackage]/build-info
# 
# solution: .SECONDARY with no prerequisites causes all targets to be treated as secondary 
# (i.e., no target is removed because it is considered intermediate).
# see https://www.gnu.org/software/make/manual/html_node/Special-Targets.html
#
# alternative would be to mark such targets as non intermediate using 
# .PRECIOUS: packages/docker/%/build-info 
#
.SECONDARY:

# ensure pnpm is available
ifeq (,$(shell command -v pnpm))
	define PNPM_NOT_FOUND
pnpm is not installed or not in PATH. 
Install it using "wget -qO- 'https://get.pnpm.io/install.sh' | sh -"
(windows : 'iwr https://get.pnpm.io/install.ps1 -useb | iex') 

See more here : https://docs.npmjs.com/getting-started/installing-node 
	endef
	$(error $(PNPM_NOT_FOUND))
else
	PNPM != command -v pnpm
endif

# ensure a recent nodejs version is available
# (required by pnpm)
ifeq (,$(shell command -v node))
	define NODEJS_NOT_FOUND
node is not installed or not in PATH. 
See more here : https://nodejs.org/en/download/ 
	endef
	$(error $(NODEJS_NOT_FOUND))
endif