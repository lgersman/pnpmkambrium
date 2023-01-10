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
packages/docker/: $(KAMBRIUM_SUB_PACKAGE_FLAVOR_DEPS) ;

#HELP: build outdated docker image by name\n\texample: 'make packages/docker/foo/' will build the docker image for 'packages/docker/foo'
packages/docker/%/: $(KAMBRIUM_SUB_PACKAGE_DEPS) ;

#
# build and tag docker image
# 
# we utilize file "build-info" to track if the docker image was build/is up to date
#
packages/docker/%/build-info: $(KAMBRIUM_SUB_PACKAGE_BUILD_INFO_DEPS)
# target depends on root located package.json and every file located in packages/docker/% except build-info
# set -a causes variables¹ defined from now on to be automatically exported.
> set -a 
# read .env file from package if exists 
> DOT_ENV="packages/docker/$*/.env"; [[ -f $$DOT_ENV ]] && source $$DOT_ENV
> PACKAGE_JSON=$(@D)/package.json
> PACKAGE_VERSION=$$(jq -r '.version | values' $$PACKAGE_JSON)
> PACKAGE_AUTHOR="$$(jq -r '.author.name | values' $$PACKAGE_JSON) <$$(jq -r '.author.email | values' $$PACKAGE_JSON)>"
> PACKAGE_NAME=$$(jq -r '.name | values' $$PACKAGE_JSON | sed -r 's/@//g')
# if DOCKER_USER is not set take the package scope (example: "@foo/bar" package user is "foo")
> DOCKER_USER=$${DOCKER_USER:-$${PACKAGE_NAME%/*}}
# if DOCKER_REPOSITORY is not set take the package repository (example: "@foo/bar" package repository is "bar")
> DOCKER_REPOSITORY=$${DOCKER_REPOSITORY:-$${PACKAGE_NAME#*/}}
> DOCKER_IMAGE="$$DOCKER_USER/$$DOCKER_REPOSITORY"
> $(PNPM) -r --filter "$$(jq -r '.name | values' $$PACKAGE_JSON)" run build
# image labels : see https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
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
> $$(echo -n "---")
> 
> $$(docker image ls $$DOCKER_IMAGE:$$PACKAGE_VERSION)
> EOF

#
# push docker images to registry
#
# see supported environment variables on make target docker-push-%
#
.PHONY: docker-push
#HELP: * push docker images to registry.\n\texample: 'DOCKER_TOKEN=your-token make docker-push' to push all docker sub packages
docker-push: $(foreach PACKAGE, $(shell ls packages/docker), $(addprefix docker-push-, $(PACKAGE))) ;

#
# push docker image to registry
# 
# environment variables can be provided either by 
# 	- environment
#		- sub package `.env` file:
#		- monorepo `.env` file
#
# supported variables are : 
# 	- DOCKER_TOKEN (required) can be the docker password (a docker token is preferred for security reasons)
# 	- DOCKER_USER use the docker identity/username, your docker account email will not work
# 	- DOCKER_REPOSITORY (optional,default=sub package name part after slash) 
# 	- DOCKER_REGISTRY (optional,default=registry.hub.docker.com)
#
.PHONY: docker-push-%
#HELP: * push a single docker image to registry.\n\texample: 'DOCKER_TOKEN=your-token make docker-push-foo' to push docker package 'packages/docker/foo'
docker-push-%: packages/docker/$*/
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
> echo "push docker image $$DOCKER_IMAGE using docker user $$DOCKER_USER"
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
> 		echo "updating description/README.md for docker image $$DOCKER_IMAGE"
# > 			cat ~/my_password.txt | docker login --username foo --password-stdin
# > 			docker login --username='$(DOCKER_USER)' --password='$(DOCKER_PASS)' $${DOCKER_HOST:-}
> 		LOGIN_PAYLOAD=$$(printf '{ "username": "%s", "password": "%s" }' "$$DOCKER_USER" "$$DOCKER_TOKEN")
> 		JWT_TOKEN=$$(curl -s --show-error --fail -H "Content-Type: application/json" -X POST -d "$$LOGIN_PAYLOAD" https://hub.docker.com/v2/users/login/ | jq --exit-status -r .token)
# 		GET : > curl -v -H "Authorization: JWT $${JWT_TOKEN}" "https://hub.docker.com/v2/repositories/$(DOCKER_IMAGE)/"
> 		DESCRIPTION=$$(docker image inspect --format='' $$DOCKER_IMAGE:latest | jq -r '.[0].Config.Labels["org.opencontainers.image.description"] | values')
# see https://frontbackend.com/linux/how-to-post-a-json-data-using-curl
# see https://stackoverflow.com/a/48470227/1554103
> 		DATA=`jq -n \
>   		--arg description "$$(jq -r '.description | values' $$PACKAGE_JSON)" \
>   		--arg full_description "$$(cat packages/docker/$*/README.md 2>/dev/null ||:)" '{description: $$description, full_description: $$full_description}' \
>			`
> 		jq . <(echo $$DATA)
>			echo $$DATA | curl -s --show-error \
> 			--fail \
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
