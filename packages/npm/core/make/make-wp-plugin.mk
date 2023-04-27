# contains generic wordpress plugin  related make settings and rules

# dynamic variable containing all js source files to transpile (wp-plugin/*/src/*.mjs files)
KAMBRIUM_WP_PLUGIN_JS_SOURCES = $$(wildcard $$(@D)/src/*.mjs)
# dynamic variable containing all transpiled js files (wp-plugin/*/build/*.js files)
KAMBRIUM_WP_PLUGIN_JS_TARGETS = $$(shell echo '$(KAMBRIUM_WP_PLUGIN_JS_SOURCES)' | sed -e 's/src/build/g' -e 's/.mjs/.js/g' )

# generic rule to transpile a single js sourcefile into its transpiled result
packages/wp-plugin/%.js : $$(subst /build/,/src/,packages/wp-plugin/$$*.mjs)
> @echo "compiling '$<' -> '$@'"

packages/wp-plugin/cm4all-wp-impex/foo.txt : $(KAMBRIUM_WP_PLUGIN_JS_TARGETS)
> @echo "$^"

# HELP<<EOF
# build and tag all outdated wordpress plugins in `packages/wp-plugin/`
#
# EOF
packages/wp-plugin/: $(KAMBRIUM_SUB_PACKAGE_FLAVOR_DEPS) ;

# HELP<<EOF
# build and zip outdated wordpress plugin package by name.
#
# plugin metadata like author/description/version will be taken from sub package file `package.json`
#
# example: `make packages/wp-plugin/foo/`
#
#   will build the wordpress plugin sub package `packages/wp-plugin/foo`
# EOF
packages/wp-plugin/%/: $(KAMBRIUM_SUB_PACKAGE_DEPS) ;

# build and zip wordpress plugin
#
# we utilize file "build-info" to track if the wordpress plugin was build/is up to date
packages/wp-plugin/%/build-info: $(KAMBRIUM_SUB_PACKAGE_BUILD_INFO_DEPS)
> # inject sub package environments from {.env,.secrets} files
> kambrium:load_env $(@D)
> PACKAGE_JSON=$(@D)/package.json
> PACKAGE_VERSION=$$(jq -r '.version | values' $$PACKAGE_JSON)
> rm -rf $(@D)/{dist,build,build-info}
> $(PNPM) -r --filter "$$(jq -r '.name | values' $$PACKAGE_JSON)" --if-present run pre-build
> if jq --exit-status '.scripts | has("build")' $$PACKAGE_JSON >/dev/null; then
>   $(PNPM)-r --filter "$$(jq -r '.name | values' $$PACKAGE_JSON)" run build
> else
>   mkdir -p $(@D)/build
>   touch $(@D)/build/foo.bar
>
>   if [[ -d $(@D)/src ]]; then
>     # transpile js/css
>     if [[ -f $(@D)/cm4all-wp-bundle.json ]]; then
>       # using cm4all-wp-bundle if a configuration file exists
>       CONFIG=$$(sed 's/^ *\/\/.*//' $(@D)/cm4all-wp-bundle.json | jq .)
>
>       for MJS in $$(find $(@D)/src -maxdepth 1 -type f -name '*.mjs' -execdir basename '{}' \;);
>       do
>         echo "transpile $$MJS"
>       done
>     else
>       # using wp-scrips as default
>       echo "[@TODO:] js/css transpilation of wp-plugin ressources using wp-scripts is not jet supported"
>       exit 1
>     fi
>   else
>     echo "[skipped]: js/css transpilation skipped - no ./src directory found"
>   fi
> fi
>
> # @TODO: build wordpress plugin
> # build js/css in src/ (take package.json src/entry info into account)
> # - generate/update i18n resources pot/mo/po
> # - update plugin.php readme.txt or use readme.txt.template => readme.txt mechnic
> # - resize/generate wordpress.org plugin images
> # - update plugin.php metadata
> # - transpile build/php sources down to 7.4. if needed (lookup required php version from plugin.php)
> # how do we store the original plugin.zip and the transpiled plugin within build/ folder ?
> $(PNPM) -r --filter "$$(jq -r '.name | values' $$PACKAGE_JSON)" --if-present run post-build
> [[ -d '$(@D)/build' ]] || (echo "don't unable to archive build directory(='$(@D)/build') : directory does not exist" >&2 && false)
> find $(@D)/build -name "*.kambrium-template" -exec rm -v -- {} \;
> mkdir -p $(@D)/dist
> # redirecting into the target zip archive frees us from removing an existing archive first
> (cd $(@D)/build && zip -9 -r -q - ./* >../dist/$*-$$PACKAGE_VERSION.zip)
> cat << EOF | tee $@
> $$(cd $(@D)/dist && ls -1shS *.zip )
>
> $$(echo -n "---")
>
> $$(unzip -l $(@D)/dist/*.zip)
> EOF

# HELP<<EOF
# push wordpress plugin to wordpress.org
#
# see supported environment variables on target `wp-plugin-push-%`
# EOF
.PHONY: wp-plugin-push
wp-plugin-push: $(foreach PACKAGE, $(shell find packages/wp-plugin/ -mindepth 1 -maxdepth 1 -type d -printf "%f " 2>/dev/null ||:), $(addprefix wp-plugin-push-, $(PACKAGE))) ;

# HELP<<EOF
# push wordpress plugin to wordpress.org
#
# target will also update
#
#   - the readme.txt description/version/author using the `description` property of sub package file `package.json`
#   - the wordpress images
#
# at wordpress.org using
#
# supported variables are:
#   - `WORDPRESS_TOKEN` (required) the wordpress.org account password
#   - `WORDPRESS_USER` (optional,default=sub package scope without `@`) the wordpress.org identity/username.
#   - `WORDPRESS_PLUGIN` (optional,default=sub package name part after `/`)
#
# environment variables can be provided using:
#   - make variables provided at commandline
#   - `.env` file from sub package
#   - `.env` file from monorepo root
#   - environment
#
# example: `make wp-plugin-push-foo WORDPRESS_USER=foo WORDPRESS_TOKEN=foobar`
#
#    will build (if outdated) the wordpress plugins and push it ot wordpress.org
# EOF
.PHONY: wp-plugin-push-%
wp-plugin-push-%: packages/wp-plugin/$$*/
> # inject sub package environments from {.env,.secrets} files
> kambrium:load_env packages/wp-plugin/$*
> PACKAGE_JSON=packages/wp-plugin/$*/package.json
> PACKAGE_NAME=$$(jq -r '.name | values' $$PACKAGE_JSON | sed -r 's/@//g')
# if WORDPRESS_USER is not set take the package scope (example: "@foo/bar" wordpress user is "foo")
> WORDPRESS_USER=$${WORDPRESS_USER:-$${PACKAGE_NAME%/*}}
# if WORDPRESS_PLUGIN is not set take the package repository (example: "@foo/bar" wordpress plugin is "bar")
> WORDPRESS_PLUGIN=$${WORDPRESS_PLUGIN:-$${PACKAGE_NAME#*/}}
> abort if WORDPRESS_TOKEN is not defined
> : $${WORDPRESS_TOKEN:?"WORDPRESS_TOKEN environment is required but not given"}
> echo "push wordpress plugin $$WORDPRESS_PLUGIN to wordpress.org using user $$WORDPRESS_USER"
> if [[ "$$(jq -r '.private | values' $$PACKAGE_JSON)" != "true" ]]; then
>   PACKAGE_VERSION=$$(jq -r '.version | values' $$PACKAGE_JSON)
>   # @TODO: push plugin to wordpress.org
>   echo '[done]'
> else
>   echo "[skipped]: package.json is marked as private"
> fi
