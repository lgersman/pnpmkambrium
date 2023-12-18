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
.RECIPEPREFIX := >

#
# disable stone age default rules enabled by default (yacc, cc and stuff)
#
MAKEFLAGS += --no-builtin-rules

#
# disable stone age default built-in rule-specific variables enabled by default (yacc, cc and stuff)
#
MAKEFLAGS += --no-builtin-variables

export DOCKER_FLAGS := -q

export DOCKER_COMPOSE_FLAGS := --progress=quiet

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

TERMINAL_GREY != tput setaf 2
TERMINAL_RED != tput setaf 1
export TERMINAL_RED
TERMINAL_YELLOW != tput setaf 3
export TERMINAL_YELLOW
TERMINAL_RESET  != tput sgr0
export TERMINAL_RESET

# use curl always with these options
# if we have curl version higher than 7.76.0 we use --fail-with-body instead of --fail
CURL := curl -s --show-error $(shell $$(curl --fail-with-body --help >/dev/null 2>&1) && echo "--fail-with-body" || echo "--fail")

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
#
# enable SECONDEXPANSION feature of make for all following targets
# see https://www.cmcrossroads.com/article/making-directories-gnu-make
.SECONDEXPANSION:

KAMBRIUM_SHELL_ALWAYS_PRELOAD += $(KAMBRIUM_MAKEFILE_DIR)/make-common.sh

# ensure pnpm is available
ifeq (,$(shell command -v pnpm))
  define PNPM_NOT_FOUND
pnpm is not installed or not in PATH.
Install it using "wget -qO- 'https://get.pnpm.io/install.sh' | sh -"
(windows : 'iwr https://get.pnpm.io/install.ps1 -useb | iex')

See more here : https://pnpm.io/installation
  endef
  $(error $(PNPM_NOT_FOUND))
else
  PNPM != command -v pnpm
endif

# pnpm env use --global $(grep -oP '(?<=use-node-version=).*' ./.npmrc1)
# node version to use by pnpm (defined in .npmrc)
NODE_VERSION != sed -n '/^use-node-version=/ {s///p;q;}' .npmrc

# path to node binary configured in .npmrc
NODE := $(HOME)/.local/share/pnpm/nodejs/$(NODE_VERSION)/bin/node

ENV_FILES := $(shell find . -type f -name '.env')

# find all *.kambrium-template marked as executable
KAMBRIUM_TEMPLATES := $(shell find . ! -path '*/dist/*' ! -path '*/build/*' -type f -executable -name '*.kambrium-template')
# transform temaplte list to a list with target files (example foo.md.kambrium-template => foo.kambrium-template)
KAMBRIUM_TEMPLATE_TARGETS := $(patsubst %.kambrium-template, %, $(KAMBRIUM_TEMPLATES))

# generic dependency for sub package build-info targets (package/*/*/build-info)
# this variables is dynamic (i.e. evaluated per use) and requires make .SECONDEXPANSION feature to be enabled
KAMBRIUM_SUB_PACKAGE_BUILD_INFO_DEPS = $$(shell find $$(@D) ! -path '*/dist/*' ! -path '*/build/*' ! -path '*/tests/*' ! -path '*/build-info' ! -path '*/node_modules/*' ! -path '*/vendor/*'  -type f) \
 $(KAMBRIUM_TEMPLATE_TARGETS) \
 $(wildcard .env) \
 package.json

#
# kambrium debugging helper function echoing the currrent target and its dependencies
#
# example usage :
#   packages/wp-plugin/%/foo: $(KAMBRIUM_SUB_PACKAGE_BUILD_INFO_DEPS)
#   > $(call KAMBRIUM_TARGET_DEPENDENCIES)
#
define KAMBRIUM_TARGET_DEPENDENCIES
  echo "Target $@ depends on prerequisites :"
  echo "$^" | tr ' ' '\n'
endef

KAMBRIUM_SUB_PACKAGE_PATHS := $(shell $(PNPM) list --recursive --filter='*/*' --json | jq -r  '.[].path' | xargs -I '{}' -r realpath --relative-base $$(pwd)/packages {})

# generic dependency for sub package targets (package/*/*/)
KAMBRIUM_SUB_PACKAGE_DEPS = $$(@D)/build-info

# generic dependency for all sub packages flavors (package/*/)
KAMBRIUM_SUB_PACKAGE_FLAVOR_DEPS = $$(addsuffix build-info,$$(wildcard $$(@D)/*/))

.PHONY: kambrium-templates
kambrium-templates: $(KAMBRIUM_TEMPLATE_TARGETS) ;
