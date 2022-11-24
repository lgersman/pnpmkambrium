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

#
# target docker registry
#
DOCKER_REGISTRY?=registry.hub.docker.com

#HELP: build all outdated docker images in packages/docker/ 
packages/docker/: $(addsuffix build-info,$(wildcard packages/docker/*/)) ;


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
> PACKAGE_NAME=$$(jq -r '.name | values' $$PACKAGE_JSON | sed -r 's/@//g')
# @TODO: inject variables from $(@D)/.env (can also be a script!)
# @TODO: call build script from $$PACKAGE_JSON if defined
# image labels : see https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
> pnpm run --if-present build $$PACKAGE_NAME
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

#
# push docker images to registry
#
.PHONY: docker-push
#HELP: * push docker images to registry
docker-push: $(foreach PACKAGE, $(shell ls packages/docker), $(addprefix docker-push-, $(PACKAGE))) ;

#
# push docker image to registry
# 
# used registry can be configured using variable DOCKER_REGISTRY
#
docker-push-%: packages/docker/$*/ guard-env-DOCKER_TOKEN
> @
> PACKAGE_JSON=packages/docker/$*/package.json
> PACKAGE_NAME=$$(jq -r '.name | values' $$PACKAGE_JSON | sed -r 's/@//g')
> echo -n "push docker image $$PACKAGE_NAME "
> if [[ "$$(jq -r '.private | values' $$PACKAGE_JSON)" != "true" ]]; then  
> 	PACKAGE_VERSION=$$(jq -r '.version | values' $$PACKAGE_JSON)
> 	# docker login --username [username] and docker access-token or real password must be initially before push
> 	echo $(DOCKER_TOKEN) | docker login --username uuu --password-stdin $(DOCKER_REGISTRY) 
> 	echo docker push $$PACKAGE_NAME:latest
> 	echo docker push $$PACKAGE_NAME:$$PACKAGE_VERSION
>		echo '[done]'
> else 
> 	echo "[skipped]: package.json is marked as private"
> fi



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
