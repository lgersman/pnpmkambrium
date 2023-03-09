# contains generic wordpress plugin  related make settings and rules

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
> # import kambrium bash function library
> . "$(KAMBRIUM_MAKEFILE_DIR)/make-bash-functions.sh"
# target depends on root located package.json and every file located in packages/wp-plugin/% except build-info
# set -a causes variables defined from now on to be automatically exported.
> set -a 
# read .env file from package if exists 
> DOT_ENV="packages/wp-plugin/$*/.env"; [[ -f $$DOT_ENV ]] && source $$DOT_ENV
> PACKAGE_JSON=$(@D)/package.json
> PACKAGE_VERSION=$$(jq -r '.version | values' $$PACKAGE_JSON)
> PACKAGE_AUTHOR="$$(kambrium:author_name $$PACKAGE_JSON) <$$(kambrium:author_email $$PACKAGE_JSON)>"
> PACKAGE_NAME=$$(jq -r '.name | values' $$PACKAGE_JSON | sed -r 's/@//g')
> rm -rf $(@D)/{dist,build}
> mkdir -p $(@D)/{dist,build}
> # @TODO: build wordpress plugin
> # - build js/css in src/ (take package.json src/entry info into account)
> # - generate/update i18n resources pot/mo/po
> # - update plugin.php readme.txt or use readme.txt.template => readme.txt mechnic
> # - resize/generate wordpress.org plugin images
> # - update plugin.php metadata 
> # - transpile build/php sources down to 7.4. if needed (lookup required php version from plugin.php)
> # how do we store the original plugin.zip and the transpiled plugin within build/ folder ?  
> $(PNPM) -r --filter "$$(jq -r '.name | values' $$PACKAGE_JSON)" run build
> # @TODO: zip build/* folder contents 
# > (cd $(@D) && pnpm pack --pack-destination ./dist >/dev/null)
# > ARCHIVE_NAME="$$(basename $<)-v$${PLUGIN_VERSION}.zip"
# > cd $< && zip -qq -r -o ../$$ARCHIVE_NAME * 
> # output zip archives 
> cat << EOF | tee $@
> $$(cd $(@D)/dist && ls -1shS *.zip) 
> 
> $$(echo -n "---")
> 
> @TODO: list archive contents
> (tar -ztf $(@D)/dist/*.zip | sort)
> EOF

PHONY: foo
foo:
> # import kambrium bash function library
> . "$(KAMBRIUM_MAKEFILE_DIR)/make-bash-functions.sh"
> # read .env file from package if exists 
> DOT_ENV="packages/wp-plugin/bulgur/.env"; [[ -f $$DOT_ENV ]] && source $$DOT_ENV
> PACKAGE_JSON=packages/wp-plugin/bulgur/package.json
> AUTHOR_NAME=$$(kambrium:author_name $$PACKAGE_JSON)
> echo "AUTHOR_NAME=$$AUTHOR_NAME"

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
# read .env file from package if exists 
> DOT_ENV="packages/wp-plugin/$*/.env"; [[ -f $$DOT_ENV ]] && source $$DOT_ENV
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
