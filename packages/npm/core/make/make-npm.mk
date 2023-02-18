# contains generic npm related make settings and rules

#
# target npm registry
#
export NPM_REGISTRY?=https://registry.npmjs.org/

# HELP<<EOF
# build all outdated npm sub packages in `packages/npm/`
# EOF
packages/npm/: $(KAMBRIUM_SUB_PACKAGE_FLAVOR_DEPS) ;

# HELP<<EOF
# build outdated npm package by name
# 
# example: `make packages/npm/foo/` 
# 
#    will build the npm sub package in `packages/npm/foo`
# EOF
packages/npm/%/: $(KAMBRIUM_SUB_PACKAGE_DEPS) ;

#
# build npm package
# 
# we utilize file "build-info" to track if the package was build/is up to date
#
packages/npm/%/build-info: $(KAMBRIUM_SUB_PACKAGE_BUILD_INFO_DEPS)
# target depends on root located package.json and every file located in packages/npm/% except build-info 
# set -a causes variables¹ defined from now on to be automatically exported.
> set -a
# read .env file from package if exists
> DOT_ENV="$(@D)/.env"; [[ -f $$DOT_ENV ]] && source $$DOT_ENV
> PACKAGE_JSON=$(@D)/package.json
> rm -f $(@D)/dist/*.tgz
> $(PNPM) -r --filter "$$(jq -r '.name | values' $$PACKAGE_JSON)" run build
> (cd $(@D) && pnpm pack --pack-destination ./dist >/dev/null)
> cat << EOF | tee $@
> $$(cd $(@D)/dist && ls -1shS *.tgz) 
> 
> $$(echo -n "---")
> 
> $$(tar -ztf $(@D)/dist/*.tgz)
> EOF

# HELP<<EOF
# pushes all npm sub packages to a npm registry
#
# see supported environment variables on target `npm-push-%`
# 
# example: `make npm-push NPM_TOKEN=your-token' 
#  
#    pushes all npm sub packages in `packages/npm/` to the npm registry
# EOF
.PHONY: npm-push
npm-push: $(foreach PACKAGE, $(shell ls packages/npm), $(addprefix npm-push-, $(PACKAGE))) ;

# HELP<<EOF
# push npm package to registry
# 
# supported variables are : 
#   - `NPM_TOKEN` (required) can be the npm password (a npm token is preferred for security reasons)
#   - `NPM_REGISTRY` (optional, default is `https://registry.npmjs.org/`)
#
# environment variables can be provided using:
#   - make variables provided at commandline
#   - `.env` file from sub package
#   - `.env` file from monorepo root
#   - environment
#
# example: `NPM_TOKEN=your-token make npm-push-foo` 
#
#    to publish npm sub package `foo` in `packages/npm/foo` to the npm registry
# 
# EOF
.PHONY: npm-push-%
npm-push-%: packages/npm/$$*/
> # read .env file from package if exists 
> DOT_ENV="packages/npm/$*/.env"; [[ -f $$DOT_ENV ]] && source $$DOT_ENV
> PACKAGE_JSON=packages/npm/$*/package.json
> PACKAGE_NAME=$$(jq -r '.name | values' $$PACKAGE_JSON)
> # abort if NPM_TOKEN is not defined 
> : $${NPM_TOKEN:?"NPM_TOKEN environment is required but not given"}
> echo "push npm package $$PACKAGE_NAME"
> if [[ "$$(jq -r '.private | values' $$PACKAGE_JSON)" != "true" ]]; then  
>   # bash does not allow declaring env variables containing "/" 
>   env "npm_config_$$NPM_REGISTRY:_authtoken=$$NPM_TOKEN" $(SHELL) -c "env | grep npm_ && pnpm -r --filter $$PACKAGE_NAME publish --no-git-checks"
>    echo '[done]'
> else
>   echo "[skipped]: package.json is marked as private"
> fi
