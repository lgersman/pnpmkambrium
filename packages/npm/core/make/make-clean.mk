# clean related targets

# HELP<<EOF
# delete resources matching `.gitignore` entries except
#
#    - `./.node_modules`
#    - any `.env` file (recursive)
#    - `./.pnpm-store`
#    - `./*.code-workspace`
# EOF
.PHONY: clean
clean: PACKAGE_DIR?=$(CURDIR)
clean:
# remove everything matching .gitignore entries (-f is force, you can add -q to suppress command output, exclude node_modules and node_modules/**)
#   => If an untracked directory is managed by a different git repository, it is not removed by default. Use -f option twice if you really want to remove such a directory.
> git clean -Xfd -e '!.secrets' -e '!.env' -e '!/*.code-workspace' -e '!**/node_modules' -e '!**/node_modules/**' -e '!**/.pnpm-store' -e '!**/pnpm-store/**' -- $(PACKAGE_DIR)
# remove temporary files outside repo
> rm -rf -- $$(dirname $(KAMBRIUM_TMPDIR))/*.pnpmkambrium-$$(basename $(CURDIR))

# HELP<<EOF
# delete any file that are a result of making the project and not matched by `.gitignore` except :
#    - any `.env` file (recursive)
#    - `./*.code-workspace`
#
# ATTENTION: You have to call 'make node_modules/' afterwards to make your environment again work properly
# EOF
# see https://www.gnu.org/software/make/manual/html_node/Standard-Targets.html
.PHONY: distclean
distclean: clean
> git clean -Xfd -e '!.secrets' -e '!/*.env' -e '!/*.code-workspace'
> rm -f pnpm-lock.yaml
# remove built docker images
> docker image rm -f $$(docker images -q $(MONOREPO_SCOPE)/*) 2>/dev/null ||:
# clean up unused containers. Container, networks, images, and the build cache
# > docker system prune -a
# remove unused volumes
# > docker volumes prune


# this is a dummy target just for providing documentation/help for dynamically generated clean-[package-flavor]/[package-name] targets
# HELP<<EOF
# clean a sub package
#
# example: `make clean-npm/foo`
#
#    will clean sub package `foo` of flavor `npm`
# EOF
.PHONY: clean-%/%
clean-%/%: ;

define CLEAN_SUBPACKAGE_RULE_TEMPLATE =
.PHONY: ${1:%=clean-%}
${1:%=clean-%}:
> $(MAKE) clean PACKAGE_DIR=${1:%=packages/%}
endef

$(foreach sub_package, $(KAMBRIUM_SUB_PACKAGE_PATHS), $(eval $(call CLEAN_SUBPACKAGE_RULE_TEMPLATE, $(sub_package))))
