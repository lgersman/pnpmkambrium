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
export DOCKER_REGISTRY?=registry.hub.docker.com

#HELP: build all outdated docker images in packages/docker/ 
packages/docker/: $(addsuffix build-info,$(wildcard packages/docker/*/)) ;


#HELP: build outdated docker image by name\n\texample: 'pnpm make packages/docker/foo/' will build the docker image for 'packages/docker/foo'
packages/docker/%/: packages/docker/%/build-info ;

#
# build and tag docker image
# 
# we utilize file "build-info" to track if the docker image was build/is up to date
#
packages/docker/%/build-info: $(filter-out packages/docker/%/build-info,$(wildcard packages/docker$*/* packages/docker$*/**/*)) package.json 
# read .env file from package if exists 
> DOT_ENV="packages/docker/$*/.env"; [[ -f $$DOT_ENV ]] && source $$DOT_ENV
# target depends on root located package.json and every file located in packages/docker/% except build-info 
> PACKAGE_JSON=$(@D)/package.json
> PACKAGE_VERSION=$$(jq -r '.version | values' $$PACKAGE_JSON)
> PACKAGE_AUTHOR="$$(jq -r '.author.name | values' $$PACKAGE_JSON) <$$(jq -r '.author.email | values' $$PACKAGE_JSON)>"
> PACKAGE_NAME=$$(jq -r '.name | values' $$PACKAGE_JSON | sed -r 's/@//g')
# if DOCKER_USER is not set take the package scope (example: "@foo/bar" package user is "foo")
> DOCKER_USER=$${DOCKER_USER:-$${PACKAGE_NAME%/*}}
# if DOCKER_REPOSITORY is not set take the package repository (example: "@foo/bar" package repository is "bar")
> DOCKER_REPOSITORY=$${DOCKER_REPOSITORY:-$${PACKAGE_NAME#*/}}
> DOCKER_IMAGE="$$DOCKER_USER/$$DOCKER_REPOSITORY"
# @TODO: inject variables from $(@D)/.env (can also be a script!)
# @TODO: call build script from $$PACKAGE_JSON if defined
# image labels : see https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
> pnpm run --if-present build $$PACKAGE_NAME
> docker build \
> 	--progress=plain \
>		-t $$DOCKER_IMAGE:latest \
> 	-t $$DOCKER_IMAGE:$$PACKAGE_VERSION \
>		--label "maintainer=$$PACKAGE_AUTHOR" \
> 	--label "org.opencontainers.image.title=$$DOCKER_IMAGE" \
> 	--label "org.opencontainers.image.description=$$(jq -r '.description | values' $$PACKAGE_JSON)" \
> 	--label "org.opencontainers.image.authors=$$PACKAGE_AUTHOR" \
>		--label "org.opencontainers.image.source=$$(jq -r -e '.repository.url | values' $$PACKAGE_JSON || jq -r '.repository.url | values' package.json)" \
> 	--label "org.opencontainers.image.url=$$(jq -r -e '.homepage | values' $$PACKAGE_JSON || jq -r '.homepage | values' package.json)" \
> 	--label "org.opencontainers.image.vendor=https://cm4all.com" \
> 	--label "org.opencontainers.image.licenses=$$(jq -r -e '.license | values' $$PACKAGE_JSON || jq -r '.license | values' package.json)" \
> 	-f $(@D)/Dockerfile .
# output generated image labels
> cat << EOF | tee $@
> $$(docker image inspect $$DOCKER_IMAGE:latest | jq '.[0].Config.Labels | values')
> 
> ---
> 
> $$(docker image ls $$DOCKER_IMAGE:$$PACKAGE_VERSION)
> EOF

#
# push docker images to registry
#
# see supported enviuronment variables on make target docker-push-%
#
.PHONY: docker-push
#HELP: * push docker images to registry.\n\texample: 'DOCKER_TOKEN=your-docker-token pnpm make docker-push' to push all docker sub packages
docker-push: $(foreach PACKAGE, $(shell ls packages/docker), $(addprefix docker-push-, $(PACKAGE))) ;

#
# push docker image to registry
# 
# environment variables can be provided either by 
# 	- environment
#		- docker package `.env` file:
#		- monorepo `.env` file
#
# supported variables are : 
# 	- DOCKER_TOKEN (required) can be the docker password (a docker token is preferred for security reasons)
# 	- DOCKER_USER use the docker identity/username, your docker account email will not work
# 	- DOCKER_REPOSITORY =xxxx
# 	- DOCKER_REGISTRY=xxx
#
#HELP: * push a single docker image to registry.\n\texample: 'DOCKER_TOKEN=your-docker-token pnpm make docker-push-gum' to push docker 'package packages/docker/gum'
docker-push-%: packages/docker/$*/
# > @
# read .env file from package if exists 
> DOT_ENV="packages/docker/$*/.env"; [[ -f $$DOT_ENV ]] && source $$DOT_ENV
> PACKAGE_JSON=packages/docker/$*/package.json
> PACKAGE_NAME=$$(jq -r '.name | values' $$PACKAGE_JSON | sed -r 's/@//g')
# if DOCKER_USER is not set take the package scope (example: "@foo/bar" package user is "foo")
> DOCKER_USER=$${DOCKER_USER:-$${PACKAGE_NAME%/*}}
# if DOCKER_REPOSITORY is not set take the package repository (example: "@foo/bar" package repository is "bar")
> DOCKER_REPOSITORY=$${DOCKER_REPOSITORY:-$${PACKAGE_NAME#*/}}
> DOCKER_IMAGE="$$DOCKER_USER/$$DOCKER_REPOSITORY"
# abort if DOCKER_TOKEN is not defined 
> : $${DOCKER_TOKEN:?"DOCKER_TOKEN environment is required but not given"}
> echo -n "push docker image $$DOCKER_IMAGE using docker user $$DOCKER_USER "
> if [[ "$$(jq -r '.private | values' $$PACKAGE_JSON)" != "true" ]]; then  
> 	PACKAGE_VERSION=$$(jq -r '.version | values' $$PACKAGE_JSON)
> 	# docker login --username [username] and docker access-token or real password must be initially before push
> 	echo "$$DOCKER_TOKEN" | docker login --username "$$DOCKER_USER" --password-stdin $$DOCKER_REGISTRY
> 	docker push $$DOCKER_IMAGE:latest
> 	docker push $$DOCKER_IMAGE:$$PACKAGE_VERSION
>		echo '[done]'
> 
>		# if DOCKER_REGISTRY == registry.hub.docker.com : update description and README.md
>		if [[ "$$DOCKER_REGISTRY" == "registry.hub.docker.com" ]]; then
> 		echo -n "updating description/README.md for docker image $$DOCKER_IMAGE using docker user $$DOCKER_USER "
# > 			cat ~/my_password.txt | docker login --username foo --password-stdin
# > 			docker login --username='$(DOCKER_USER)' --password='$(DOCKER_PASS)' $${DOCKER_HOST:-}
> 		LOGIN_PAYLOAD=$$(printf '{ "username": "%s", "password": "%s" }' "$$DOCKER_USER" "$$DOCKER_TOKEN")
> 		JWT_TOKEN=$$(curl -s --show-error  -H "Content-Type: application/json" -X POST -d "$$LOGIN_PAYLOAD" https://hub.docker.com/v2/users/login/ | jq --exit-status -r .token)
# 		GET : > curl -v -H "Authorization: JWT $${JWT_TOKEN}" "https://hub.docker.com/v2/repositories/$(DOCKER_IMAGE)/"
> 		DESCRIPTION=$$(docker image inspect --format='' $$DOCKER_IMAGE:latest | jq -r '.[0].Config.Labels["org.opencontainers.image.description"] | values')
# see https://frontbackend.com/linux/how-to-post-a-json-data-using-curl
# see https://stackoverflow.com/a/48470227/1554103
> 		jq -n \
>   		--arg description "$$(jq -r '.description | values' $$PACKAGE_JSON)" \
>   		--arg full_description "$$(cat packages/docker/$*/README.md 2>/dev/null ||:)" '{description: $$description, full_description: $$full_description}' \
>			| curl -s --show-error \
> 			-H "Content-Type: application/json" \
>				-H "Authorization: JWT $${JWT_TOKEN}" \
> 			-X PATCH \
>				--data-binary @- \
> 			"https://hub.docker.com/v2/repositories/$$DOCKER_IMAGE/" \
> 		| jq .
>			echo '[done]'
> 	fi
>
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
