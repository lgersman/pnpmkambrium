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
include $(KAMBRIUM_MAKEFILE_DIR)/make-pnpm.mk
include $(KAMBRIUM_MAKEFILE_DIR)/make-init.mk
include $(KAMBRIUM_MAKEFILE_DIR)/make-lint.mk
include $(KAMBRIUM_MAKEFILE_DIR)/make-clean.mk
include $(KAMBRIUM_MAKEFILE_DIR)/make-docker.mk
include $(KAMBRIUM_MAKEFILE_DIR)/make-wp-plugin.mk
include $(KAMBRIUM_MAKEFILE_DIR)/make-npm.mk
include $(KAMBRIUM_MAKEFILE_DIR)/make-generic.mk
include $(KAMBRIUM_MAKEFILE_DIR)/make-docs.mk
include $(KAMBRIUM_MAKEFILE_DIR)/make-gh-pages.mk
include $(KAMBRIUM_MAKEFILE_DIR)/make-github.mk
include $(KAMBRIUM_MAKEFILE_DIR)/make-help.mk

# ensure required utilities are installed
_ := $(call ensure-commands-exists, sed git touch jq docker tee awk)

# pick up npm scope from package.json name
MONOREPO_SCOPE != jq -r '.name | values' package.json

# project (path) specific temp directory outside of the checked out repository
KAMBRIUM_TMPDIR := $(shell mktemp -d --suffix ".pnpmkambrium-$$(basename $(CURDIR))")
# delete all KAMBRIUM_TMPDIR's older than one day
$(shell find $(shell dirname $(KAMBRIUM_TMPDIR)) -maxdepth 0 -ctime +1 -name '*.*.pnpmkambrium-$(shell basename $(CURDIR))' -type d -delete)
