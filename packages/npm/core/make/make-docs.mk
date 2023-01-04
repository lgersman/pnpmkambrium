# contains generic docs related make settings and rules

#HELP: build all outdated docs in packages/docs/ 
packages/docs/: $(addsuffix build-info,$(wildcard packages/docs/*/)) ;


#HELP: build outdated docs package by name\n\texample: 'make packages/docs/gh-pages/' will build 'packages/docs/gh-pages'
packages/docs/%/: packages/docs/%/build-info ;

#
# build docs package
# 
# we utilize file "build-info" to track if the package was build/is up to date
#
packages/docs/%/build-info: $(filter-out packages/docs/%/build-info,$(wildcard packages/docs$*/* packages/docs$*/**/*)) package.json 
# target depends on root located package.json and every file located in packages/docs/% except build-info 
# > @
# ensure mdbook image is available
> @$(call ensure-docker-images-exists, pnpmkambrium/mdbook)
> . "$(KAMBRIUM_MAKEFILE_DIR)/make-bash-functions.sh"
# set -a causes variables¹ defined from now on to be automatically exported.
> set -a
# read .env file from package if exists
> DOT_ENV="packages/docs/$*/.env"; [[ -f $$DOT_ENV ]] && source $$DOT_ENV
> PACKAGE_JSON=$(@D)/package.json
> PACKAGE_VERSION=$$(jq -r '.version | values' $$PACKAGE_JSON)
> PACKAGE_NAME=$$(jq -r '.name | values' $$PACKAGE_JSON | sed -r 's/@//g')
> PACKAGE_DESCRIPTION=$$(jq -r '.description | values' $$PACKAGE_JSON)
# if package.json has a build script execute package script build. otherwise run mdbook
> if jq --exit-status '.scripts | has("build")' $$PACKAGE_JSON >/dev/null; then
> 	echo $(PNPM) -r --filter "$$(jq -r '.name | values' $$PACKAGE_JSON)" run build
> else
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
> 	MDBOOK_GITHUB_REPOSITORY_URL="$$(\
			jq --exit-status -r '.repository.url | select(.!=null)' $$PACKAGE_JSON || \
			jq --exit-status -r '.repository.url | select(.!=null)' package.json \
		)"
> 	docker run --rm -it -e "MDBOOK_BOOK=$$MDBOOK_BOOK" -e "MDBOOK_OUTPUT_HTML_git__repository__url=$$MDBOOK_GITHUB_REPOSITORY_URL" --mount type=bind,source=$$(pwd)/$(@D),target=/data -u $$(id -u):$$(id -g) pnpmkambrium/mdbook mdbook build
> fi
> mkdir -p $(@D)/dist
# redirecting into the target zip archive frees us from removing an existing archive first
> (cd $(@D)/build && zip -9 -r -q - ./* >../dist/$*-$$PACKAGE_VERSION.zip)
> cat << EOF | tee $@
> $$(cd $(@D)/dist && ls -1shS *.zip ) 
> 
> $$(echo -n "---")
> 
> $$(unzip -l $(@D)/dist/*.zip)
> EOF


