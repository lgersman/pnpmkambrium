# contains generic docs related make settings and rules

# HELP<<EOF
# build all outdated doc sub packages in `'packages/docs/'`
#
# see supported environment variables on target `packages/docs/%/`
# EOF
packages/docs/: $(KAMBRIUM_SUB_PACKAGE_FLAVOR_DEPS) ;

# HELP<<EOF
# build outdated docs sub package by name
#
# task utilizes various informations from `'package.json'` like authors/contributors/title/etc.
#
# the following mdbook configuration options can be provided by environment variables: 
# 	- `MDBOOK_GIT_REPOSITORY_URL` (optional, default=repository.url from (sub|root)package.json) 
# 	- `MDBOOK_GIT_REPOSITORY_ICON` (optional, default=`'fa-code-fork'`) 
# 	- `MDBOOK_GIT_URL_TEMPLATE` (optional), 
#		(see https://rust-lang.github.io/mdBook/format/configuration/renderers.html#html-renderer-options)
#
# environment variables can be provided using:
# 	- make variables provided at commandline
#		- `'.env'` file from sub package
#		- `'.env'` file from monorepo root
# 	- environment
#
# example: `make packages/docs/gh-pages/`
#
#		will rebuild outdated sub package `'packages/docs/gh-pages'`
# EOF
packages/docs/%/: $(KAMBRIUM_SUB_PACKAGE_DEPS) ;

#
# build docs package
# 
# we utilize file "build-info" to track if the package was build/is up to date
#
# target depends on root located package.json and every file located in packages/docs/% except build-info 
packages/docs/%/build-info: $(KAMBRIUM_SUB_PACKAGE_BUILD_INFO_DEPS)
> # import kambrium bash function library
> . "$(KAMBRIUM_MAKEFILE_DIR)/make-bash-functions.sh"
> # set -a causes variables defined from now on to be automatically exported.
> set -a
> # read .env file from package if exists
> DOT_ENV="packages/docs/$*/.env"; [[ -f $$DOT_ENV ]] && source $$DOT_ENV
> PACKAGE_JSON=$(@D)/package.json
> PACKAGE_VERSION=$$(jq -r '.version | values' $$PACKAGE_JSON)
> PACKAGE_NAME=$$(jq -r '.name | values' $$PACKAGE_JSON | sed -r 's/@//g')
> PACKAGE_DESCRIPTION=$$(jq -r '.description | values' $$PACKAGE_JSON)
> # if package.json has a build script execute package script build. otherwise run mdbook
> if jq --exit-status '.scripts | has("build")' $$PACKAGE_JSON >/dev/null; then
> 	$(PNPM) --filter "$$(jq -r '.name | values' $$PACKAGE_JSON)" run build
>		if jq --exit-status '.scripts | has("dev")' $$PACKAGE_JSON >/dev/null; then
>			$(PNPM) --filter "$$(jq -r '.name | values' $$PACKAGE_JSON)" run dev
>		else
>			echo 'error: generic build/watch is not implemented yet' >&2
>			exit 1
>			# @TODO: add generic build/watch with browser refresh
>		fi
> else
> 	# ensure mdbook image is available
> 	$(call ensure-docker-images-exists, pnpmkambrium/mdbook)
>		# prepare configuration
> 	MDBOOK_AUTHORS=$$(kambrium:jq:first_non_empty_array \
			"$$(jq '[.contributors[]? | .name]' $$PACKAGE_JSON)" \
			"$$(jq '[.author.name | select(.|.!=null)]' $$PACKAGE_JSON)" \
			"$$(jq '[.contributors[]? | .name]' package.json)" \
			"$$(jq '[.author.name | select(.|.!=null)]' package.json)" \
		)
>		MDBOOK_BOOK=$$(jq -n --compact-output \
			--arg title "$$PACKAGE_NAME" \
     	--arg description "$$PACKAGE_DESCRIPTION" \
			--argjson authors "$$MDBOOK_AUTHORS" \
			'{title: $$title, description: $$description, authors: $$authors}' \
		)
> 	MDBOOK_GIT_REPOSITORY_URL="$$(\
			printenv MDBOOK_GIT_REPOSITORY_URL || \
			jq --exit-status -r '.repository.url | select(.!=null)' $$PACKAGE_JSON || \
			jq --exit-status -r '.repository.url | select(.!=null)' package.json \
		)"
>		MDBOOK_GIT_URL_TEMPLATE="$${MDBOOK_GIT_URL_TEMPLATE:-}"
>		MDBOOK_GIT_REPOSITORY_ICON="$${MDBOOK_GIT_REPOSITORY_ICON:-fa-code-fork}"
>		if [[ "$${KAMBRIUM_DEV_MODE:-}" == "true" ]]; then
>			docker run --rm -it \
				-e "MDBOOK_BOOK=$$MDBOOK_BOOK" \
				-e "MDBOOK_OUTPUT__HTML__git_repository_url=$$MDBOOK_GIT_REPOSITORY_URL" \
				-e "MDBOOK_OUTPUT__HTML__git_repository_icon=$$MDBOOK_GIT_REPOSITORY_ICON" \
				-e "MDBOOK_OUTPUT__HTML__edit_url_template=$$MDBOOK_GIT_URL_TEMPLATE" \
				--mount type=bind,source=$$(pwd)/$(@D),target=/data \
				-u $$(id -u):$$(id -g) \
				-p 3000:3000 -p 3001:3001 \
				pnpmkambrium/mdbook mdbook serve -n 0.0.0.0
>		fi
>		docker run --rm -it \
			-e "MDBOOK_BOOK=$$MDBOOK_BOOK" \
			-e "MDBOOK_OUTPUT__HTML__git_repository_url=$$MDBOOK_GIT_REPOSITORY_URL" \
			--mount type=bind,source=$$(pwd)/$(@D),target=/data \
			-u $$(id -u):$$(id -g) \
			pnpmkambrium/mdbook mdbook build
> fi
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
# start dev server for a docs sub package in `'packages/docs/'`
# 
# using this target enables you to edit a docs sub package and preview it in the browser at your fingertips
#
# example: `make dev-docs-foo`
#
#		will start the dev server for docs sub package `foo`. 
# 	Every change in `'packages/docs/foo'` will result in rebuild/reloading the docs in the browser.
# EOF
.PHONY: dev-docs-%
dev-docs-%: export KAMBRIUM_DEV_MODE := true
#HELP: start dev server of docs package by name\n\texample: 'make dev-docs-gh-pages/' will build/watch 'packages/docs/gh-pages'
dev-docs-%: packages/docs/%/build-info;