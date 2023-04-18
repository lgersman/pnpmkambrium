# contains make settings and rules related to the generic sub package flavor

# HELP<<EOF
# build all outdated npm sub packages in `packages/npm/`
# EOF
packages/generic/: $(KAMBRIUM_SUB_PACKAGE_FLAVOR_DEPS) ;

# HELP<<EOF
# build outdated generic package by name
#
# example: `make packages/generic/foo/`
#
#    will build the generic sub package in `packages/generic/foo`
# EOF
packages/generic/%/: $(KAMBRIUM_SUB_PACKAGE_DEPS) ;

#
# build generic package
#
# we utilize file "build-info" to track if the package was build/is up to date
#
packages/generic/%/build-info: $(KAMBRIUM_SUB_PACKAGE_BUILD_INFO_DEPS)
> # inject sub package environments from {.env,.secrets} files
> kambrium:load_env $(@D)
> PACKAGE_JSON=$(@D)/package.json
> PACKAGE_VERSION=$$(jq -r '.version | values' $$PACKAGE_JSON)
> rm -rf $(@D)/dist
> if jq --exit-status '.scripts | has("build")' $$PACKAGE_JSON >/dev/null; then
>   $(PNPM) --filter "$$(jq -r '.name | values' $$PACKAGE_JSON)" run build
> else
>   rsync -av '$(@D)' '$(@D)/build' \
      --exclude='build' \
      --exclude='dist' \
      --exclude='test/*' \
      --exclude='tests' \
      --exclude='package.json'
> fi
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
