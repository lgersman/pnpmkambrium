# contains generic docs related make settings and rules

#HELP: build all outdated docker images in packages/docs/ 
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
# set -a causes variables¹ defined from now on to be automatically exported.
> set -a
# read .env file from package if exists
> DOT_ENV="packages/docs/$*/.env"; [[ -f $$DOT_ENV ]] && source $$DOT_ENV
> PACKAGE_JSON=$(@D)/package.json
> PACKAGE_VERSION=$$(jq -r '.version | values' $$PACKAGE_JSON)
> PACKAGE_AUTHOR="$$(jq -r '.author.name | values' $$PACKAGE_JSON) <$$(jq -r '.author.email | values' $$PACKAGE_JSON)>"
> PACKAGE_NAME=$$(jq -r '.name | values' $$PACKAGE_JSON | sed -r 's/@//g')
> PACKAGE_DESCRIPTION=$$(jq -r '.description | values' $$PACKAGE_JSON)
# if package.json has a build script execute package script build. otherwise run mdbook
> if jq --exit-status '.scripts | has("build")' $$PACKAGE_JSON 1>/dev/null; then
> 	echo $(PNPM) -r --filter "$$(jq -r '.name | values' $$PACKAGE_JSON)" run build
> else
>		MDBOOK_BOOK=$$(jq -n --compact-output \
			--arg title "$$PACKAGE_NAME" \
     	--arg description "$$PACKAGE_DESCRIPTION" \
			--argjson authors "$$(jq --compact-output -j '[.contributors[]? | .name]' $$PACKAGE_JSON)" \
			'{title: $$title, description: $$description, authors: $$authors}' \
		)
>		# @TODO: add link to github repo
>		# @TODO: fallback to author if contributors are not available
> 	docker run --rm -it -e "MDBOOK_BOOK=$$MDBOOK_BOOK" --mount type=bind,source=$$(pwd)/$(@D),target=/data -u $$(id -u):$$(id -g) pnpmkambrium/mdbook mdbook build
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

