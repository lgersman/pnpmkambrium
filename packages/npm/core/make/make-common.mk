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
# (disabled) -O starglob enables extended globbing (example foo/**/*)
#
.SHELLFLAGS := -eu -o pipefail -c 

#
# disable stone age default rules enabled by default (yacc, cc and stuff)
#
MAKEFLAGS += --no-builtin-rules


#
# disable stone age default built-in rule-specific variables enabled by default (yacc, cc and stuff)
#
MAKEFLAGS += ----no-builtin-variables

export DOCKER_FLAGS := -q

#
# warn if unused variables in use
#
MAKEFLAGS += --warn-undefined-variables

#
# suppress "entering directory ..." messages
#
MAKEFLAGS += --no-print-directory

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
# .SECONDARY:
# 
# > You can disable intermediate files completely in your makefile by providing .NOTINTERMEDIATE as a target with no prerequisites: 
# > in that case it applies to every file in the makefile.
# .NOTINTERMEDIATE:

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

TERMINAL_GREY != tput setaf 2
TERMINAL_YELLOW != tput setaf 3
TERMINAL_RESET  != tput sgr0

# use curl always with these options 
# if we have curl version higher than 7.76.0 we use --fail-with-body instead of --fail
CURL := curl -s --show-error $(shell $$(curl --fail-with-body --help >/dev/null 2>&1) && echo "--fail-with-body" || echo "--fail")



# enable SECONDEXPANSION feature of make for all following targets
# see https://www.cmcrossroads.com/article/making-directories-gnu-make
.SECONDEXPANSION:

# generic dependency for sub package build-info targets (package/*/*/build-info)
# this variables is dynamic (i.e. evaluated per use) and requires make .SECONDEXPANSION feature to be enabled
KAMBRIUM_SUB_PACKAGE_BUILD_INFO_DEPS = $$(shell find $$(@D) ! -path '*/dist/*' ! -path '*/build/*' ! -path '*/build-info'  -type f) package.json

# generic dependency for sub package targets (package/*/*/)
KAMBRIUM_SUB_PACKAGE_DEPS = $(TEMPLATE_TARGETS) $$(@D)/build-info 

# generic dependency for all sub packages flavors (package/*/)
KAMBRIUM_SUB_PACKAGE_FLAVOR_DEPS = $$(addsuffix build-info,$$(wildcard $$(@D)/*/))