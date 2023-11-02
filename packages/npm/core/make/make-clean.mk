# clean related targets

# HELP<<EOF
# delete resources matching `.gitignore` entries except
#
#    - `./.node_modules`
#    - any `.env` file (recursive)
#    - any `.secrets` file (recursive)
#    - `./.pnpm-store`
#    - `./*.code-workspace`
#
# supported make variables variables:
#   - `IMPEX_GIT_CLEAN_ARGS` (default=`-Xfd -e '!.secrets' -e '!.env' -e '!/*.code-workspace' -e '!**/node_modules' -e '!**/node_modules/**' -e '!/.pnpm-store' --interactive`)
#   - `IMPEX_BEFORE_CLEAN_HOOKS` (default=`true`) - shell commands to execute before cleaning
#
# customization Makefile example:
#
#   ```Makefile
#   \# include kambrium base makefile
#   include node_modules/@pnpmkambrium/core/make/make.mk
#
#   \# define custom variable keeping our shell code to execute before cleaning
#   IMPEX_BEFORE_CLEAN_HOOKS := && ([[ ! -d "$(WP_ENV_HOME)" ]] || echo 'y' | $(MAKE) -s wp-env-destroy)
#
#   \# add our hook to possibly existing hooks
#   clean: BEFORE_CLEAN_HOOKS += $(IMPEX_BEFORE_CLEAN_HOOKS)
#
#   \# define custom variale keeping extra arguments for git clean
#   IMPEX_GIT_CLEAN_ARGS := -e '!/.wp-env.json' -e '!/.wp-env.override.json' -e '!/.wp-env-afterStart.sh' -e '!/TODO.md'
#
#   \# add our git args to git clean arguments of clean target
#   clean: GIT_CLEAN_ARGS += $(IMPEX_GIT_CLEAN_ARGS) -e '!.vscode/launch.json' -e '!/wp-env-backup'
#   \# add our git args to git clean arguments of clean target
#   distclean: GIT_CLEAN_ARGS += $(IMPEX_GIT_CLEAN_ARGS)
#   ```
#
# EOF
.PHONY: clean
clean: PACKAGE_DIR ?= $(CURDIR)
clean: GIT_CLEAN_ARGS := -Xfd -e '!.secrets' -e '!.env' -e '!/*.code-workspace' -e '!**/node_modules' -e '!**/node_modules/**' -e '!/.pnpm-store' --interactive
clean: BEFORE_CLEAN_HOOKS ?= true
clean:
> $(BEFORE_CLEAN_HOOKS)
# remove everything matching .gitignore entries (-f is force, you can add -q to suppress command output, exclude node_modules and node_modules/**)
#   => If an untracked directory is managed by a different git repository, it is not removed by default. Use -f option twice if you really want to remove such a directory.
> git clean $(GIT_CLEAN_ARGS) -- $(PACKAGE_DIR)
# remove temporary files outside repo
> rm -rf -- $$(dirname $(KAMBRIUM_TMPDIR))/*.pnpmkambrium-$$(basename $(CURDIR))

# HELP<<EOF
# delete any file that are a result of making the project and not matched by `.gitignore` except :
#    - any `.env` file (recursive)
#    - any `.secrets` file (recursive)
#    - `./*.code-workspace`
#
# ATTENTION: You have to call 'make node_modules/' afterwards to make your environment again work properly
# EOF
# see https://www.gnu.org/software/make/manual/html_node/Standard-Targets.html
.PHONY: distclean
distclean: GIT_CLEAN_ARGS := -Xfd -e '!.secrets' -e '!/*.env' -e '!/*.code-workspace' --interactive
distclean: clean
> git clean $(GIT_CLEAN_ARGS)
> rm -f pnpm-lock.yaml
# remove built docker images
> docker image rm -f $$(docker images -q $(KAMBRIUM_MONOREPO_SCOPE)/*) 2>/dev/null ||:
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
.PHONY: clean-$(1)
clean-$(1):
> $(MAKE) clean PACKAGE_DIR=packages/$(1)
endef

$(foreach sub_package, $(KAMBRIUM_SUB_PACKAGE_PATHS), $(eval $(call CLEAN_SUBPACKAGE_RULE_TEMPLATE,$(sub_package))))
