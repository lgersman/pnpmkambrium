# contains generic npm related make settings and rules

#
# target npm registry
#
export NPM_REGISTRY?=https://registry.npmjs.org/

#HELP: build all outdated packages in packages/npm/ 
packages/npm/: $(addsuffix build-info,$(wildcard packages/npm/*/)) ;


#HELP: build outdated npm package by name\n\texample: 'make packages/npm/foo/' will build 'packages/npm/foo'
packages/npm/%/: packages/npm/%/build-info ;

#
# build npm package
# 
# we utilize file "build-info" to track if the package was build/is up to date
#
packages/npm/%/build-info: $(filter-out packages/npm/%/build-info,$(wildcard packages/npm$*/* packages/npm$*/**/*)) package.json 
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

#
# push npm packages to registry
#
# see supported environment variables on make target npm-push-%
#
.PHONY: npm-push
#HELP: * push npm packages to registry.\n\texample: 'NPM_TOKEN=your-token make npm-push' to push all npm sub packages
npm-push: $(foreach PACKAGE, $(shell ls packages/npm), $(addprefix npm-push-, $(PACKAGE))) ;

#
# push npm package to registry
# 
# environment variables can be provided either by 
# 	- environment
#		- sub package `.env` file:
#		- monorepo `.env` file
#
# supported variables are : 
# 	- NPM_TOKEN (required) can be the npm password (a npm token is preferred for security reasons)
# 	- NPM_REGISTRY=xxx
#
.PHONY: npm-push-%
#HELP: * push a single npm package to registry.\n\texample: 'NPM_TOKEN=your-token make npm-push-foo' to push npm package 'packages/npm/foo'
npm-push-%: packages/npm/$*/
# read .env file from package if exists 
> DOT_ENV="packages/npm/$*/.env"; [[ -f $$DOT_ENV ]] && source $$DOT_ENV
> PACKAGE_JSON=packages/npm/$*/package.json
> PACKAGE_NAME=$$(jq -r '.name | values' $$PACKAGE_JSON)
# abort if NPM_TOKEN is not defined 
> : $${NPM_TOKEN:?"NPM_TOKEN environment is required but not given"}
> echo "push npm package $$PACKAGE_NAME"
> if [[ "$$(jq -r '.private | values' $$PACKAGE_JSON)" != "true" ]]; then  
> 	# bash does not allow declaring env variables containing "/" 
> 	env "npm_config_$$NPM_REGISTRY:_authtoken=$$NPM_TOKEN" $(SHELL) -c "env | grep npm_ && pnpm -r --filter $$PACKAGE_NAME publish --no-git-checks"
>		echo '[done]'
> else
> 	echo "[skipped]: package.json is marked as private"
> fi
