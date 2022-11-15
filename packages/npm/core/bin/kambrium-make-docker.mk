# contains generic make rules for docker

#HELP: build all docker images in packages/docker/ 
packages/docker/: $(wildcard packages/docker/*/) ;

#HELP: build a docker image by name\n\tExample: 'pnpm make packages/docker/foo/' will build the docker image for 'packages/docker/foo'
packages/docker/%/: packages/docker/%/build-info ;

#
# build and tag docker image
# 
# we utilize file "build-info" to track if the docker image was build/is up to date
#
.SECONDARY: packages/docker/%/build-info
packages/docker/%/build-info: $(filter-out packages/docker/%/build-info,$(wildcard packages/docker$*/* packages/docker$*/**/*)) package.json 
# target depends on root located package.json and every file located in packages/docker/% except build-info 
> $(info docker directory is "$*")
> $(info dependencies are "$^")
> touch -m $@

# > PACKAGE_VERSION=$$(jq -r '.version | values' package.json)
# > PACKAGE_AUTHOR="$$(jq -r '.author.name | values' package.json) <$$(jq -r '.author.email | values' package.json)>"
# > NODEJS_VERSION=$$(grep -oP 'use-node-version=\K.*' .npmrc)
# # value can be alpine|bullseye|bullseye-slim
# > LINUX_DIST=bullseye-slim
# > export DOCKER_SCAN_SUGGEST=false
# > export DOCKER_BUILDKIT=1
# # image labels : see https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
# > docker build \
# > 	--progress=plain \
# > 	--build-arg nodejs_base=$$NODEJS_VERSION-$$LINUX_DIST \
# >		-t $(DOCKER_IMAGE):latest \
# > 	-t $(DOCKER_IMAGE):$$PACKAGE_VERSION \
# >		--label "maintainer=$$PACKAGE_AUTHOR" \
# > 	--label "org.opencontainers.image.title=$(DOCKER_IMAGE)" \
# > 	--label "org.opencontainers.image.description=$$(jq -r '.description | values' package.json)" \
# > 	--label "org.opencontainers.image.authors=$$PACKAGE_AUTHOR" \
# >		--label "org.opencontainers.image.source=$$(jq -r '.repository.url | values' package.json)" \
# > 	--label "org.opencontainers.image.url=$$(jq -r '.homepage | values' package.json)" \
# > 	--label "org.opencontainers.image.vendor=https://cm4all.com" \
# > 	--label "org.opencontainers.image.licenses=$$(jq -r '.license | values' package.json)" \
# > 	-f ./docker/Dockerfile .
# # output generated image labels
# # > docker image inspect --format='' $(DOCKER_IMAGE):latest 2> /dev/null | jq '.[0].Config.Labels'
# > docker image inspect --format='' $(DOCKER_IMAGE):latest | jq '.[0].Config.Labels | values'
# # output some image statistics
# > docker image ls $(DOCKER_IMAGE):$$PACKAGE_VERSION

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
