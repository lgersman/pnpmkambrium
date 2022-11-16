# contains generic docker related make settings and rules

#
# disable boring scan info while building docker images
# see https://github.com/docker/scan-cli-plugin/issues/149
#
export DOCKER_SCAN_SUGGEST:=false

#
# use  buildx for more performant image builds 
# see https://docs.docker.com/build/buildkit/
#
export DOCKER_BUILDKIT:=1

#HELP: build all outdated docker images in packages/docker/ 
packages/docker/: $(wildcard packages/docker/*/) ;

#HELP: build outdated docker image by name\n\tExample: 'pnpm make packages/docker/foo/' will build the docker image for 'packages/docker/foo'
packages/docker/%/: packages/docker/%/build-info ;

#
# build and tag docker image
# 
# we utilize file "build-info" to track if the docker image was build/is up to date
#
packages/docker/%/build-info: $(filter-out packages/docker/%/build-info,$(wildcard packages/docker$*/* packages/docker$*/**/*)) package.json 
# target depends on root located package.json and every file located in packages/docker/% except build-info 
> PACKAGE_JSON=$(@D)/package.json
> PACKAGE_VERSION=$$(jq -r '.version | values' $$PACKAGE_JSON)
> PACKAGE_AUTHOR="$$(jq -r '.author.name | values' $$PACKAGE_JSON) <$$(jq -r '.author.email | values' $$PACKAGE_JSON)>"
> IFS="/" read -r PACKAGE_SCOPE PACKAGE_NAME <<<$$(jq -r '.name | values' $$PACKAGE_JSON | sed -r 's/@//g'); unset 
# @TODO: inject variables from $(@D)/.env (can also be a script!)
# @TODO: call build script from $$PACKAGE_JSON if defined
# image labels : see https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
> docker build \
> 	--progress=plain \
>		-t $$PACKAGE_NAME:latest \
> 	-t $$PACKAGE_NAME:$$PACKAGE_VERSION \
>		--label "maintainer=$$PACKAGE_AUTHOR" \
> 	--label "org.opencontainers.image.title=$$PACKAGE_NAME" \
> 	--label "org.opencontainers.image.description=$$(jq -r '.description | values' $$PACKAGE_JSON)" \
> 	--label "org.opencontainers.image.authors=$$PACKAGE_AUTHOR" \
>		--label "org.opencontainers.image.source=$$(jq -r '.repository.url | values' $$PACKAGE_JSON)" \
> 	--label "org.opencontainers.image.url=$$(jq -r '.homepage | values' $$PACKAGE_JSON)" \
> 	--label "org.opencontainers.image.vendor=https://cm4all.com" \
> 	--label "org.opencontainers.image.licenses=$$(jq -r '.license | values' $$PACKAGE_JSON)" \
> 	-f $(@D)/Dockerfile .
# output generated image labels
> cat << EOF | tee $@
> $$(docker image inspect $$PACKAGE_NAME:latest | jq '.[0].Config.Labels | values')
> 
> ---
> 
> $$(docker image ls $$PACKAGE_NAME:$$PACKAGE_VERSION)
> EOF

# #> @: # neat trick: add this line to silent the whole task
# # switch into sub-package directory
# > cd $(@D) 
# # inject .env file 
# > test -f .env && source .env
# # pick version from package.json 
# > VERSION=`jq -r .version package.json`
# # fallback : if IMAGE is not defined via.env => eval it from package.json
# > : $${IMAGE:=`jq -r .name package.json`}
# > IMAGE="$${IMAGE/@}"
# # build the image
# # optional add --build-arg MDBOOK_VERSION='0.4.13'
# > test -f .env && source .env
# # > test -x $1 && $1
# > docker build  --tag $$IMAGE:$$VERSION -t $$IMAGE .
# # @TODO: add self hosted docker registry  ? 
