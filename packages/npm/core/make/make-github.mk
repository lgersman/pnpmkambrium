# contains GitHub related targets

KAMBRIUM_SHELL_ALWAYS_PRELOAD += $(KAMBRIUM_MAKEFILE_DIR)/make-github.sh

# HELP<<EOF
# syncs informational data like description/tags/etc. to GitHub repository metadata
#    - sync repo description and tags from root file `package.json`
#    - enable GitHub pages if a docs sub package `packages/docs/gh-pages` exists and `packages/docs/gh-pages/package.json` property 'private' is falsy
#
# supported variables are :
#   - `GITHUB_TOKEN` (required) can be the GitHub password (a GitHub token is preferred for security reasons)
#   - `GITHUB_OWNER` (required) GitHub username
#   - `GIT_REMOTE_REPOSITORY_NAME` (optional, default=`origin`) the remote repository to push to
#   - `GITHUB_REPO` (optional,default=property `repository.url` in root file `package.json`) GitHub repository name
#   - `GITHUB_REPO_DESCRIPTION` (optional,default=property `description` in root file `package.json`)
#   - `GITHUB_REPO_TOPICS` (optional,default=property `keys` in root file `package.json`)
#   - `GITHUB_REPO_HOMEPAGE` (optional,default=property `homepage` in root file `package.json`)
#
# environment variables can be provided using:
#   - make variables provided at commandline
#   - `.env` file from sub package
#   - `.env` file from monorepo root
#   - environment
#
# example: `make --silent github-details-push`
#
#    will update the GitHub repository metadata with the provided data
# EOF
.PHONY: github-details-push
# it's tricky - target will depend on 'packages/docs/gh-pages/' if packages/docs/gh-pages/package.json exists and property .private is true
github-details-push: $(shell jq --exit-status '.private? | not' packages/docs/gh-pages/package.json >/dev/null 2>&1 && echo 'packages/docs/gh-pages/build-info' || echo "")
> # https://docs.github.com/en/rest/overview/resources-in-the-rest-api?apiVersion=2022-11-28#user-agent-required
> # https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28
> # https://gist.github.com/btoone/2288960
# abort if GITHUB_TOKEN is not defined
> : $${GITHUB_TOKEN:?"GITHUB_TOKEN environment is required but not given"}
# abort if GITHUB_OWNER is not defined
> : $${GITHUB_OWNER:?"GITHUB_OWNER environment is required but not given"}
> PACKAGE_NAME=$$(jq -r '.name | values' package.json)
> GITHUB_REPO=$${GITHUB_REPO:-$$PACKAGE_NAME}
> GITHUB_REPO_DESCRIPTION=$${GITHUB_REPO_DESCRIPTION:-$$(jq --exit-status -r '.description | values' package.json)}
> GITHUB_REPO_TOPICS=$${GITHUB_REPO_TOPICS:-$$(jq --exit-status '.keywords' package.json || echo '[]')}
> GITHUB_REPO_HOMEPAGE=$${GITHUB_REPO_HOMEPAGE:-$$(jq -r --exit-status '.homepage | values' package.json)}
> echo "push '$$PACKAGE_NAME' github repo details"
> # update description and homepage
> DATA=`jq -n \
>   --arg description "$$GITHUB_REPO_DESCRIPTION" \
>   --arg homepage "$$GITHUB_REPO_HOMEPAGE" \
>   '{description: $$description, homepage: $$homepage }' \
> `
> $(CURL) \
>    -X PATCH \
>   -H "Accept: application/vnd.github+json" \
>    -H "Authorization: Bearer $$GITHUB_TOKEN"\
>    https://api.github.com/repos/$${GITHUB_OWNER}/$${GITHUB_REPO} \
>   --data "$$DATA" \
>   | jq '{ description, homepage }'
> # update topics
> # Note: To edit a repository's topics, use the Replace all repository topics endpoint.
> # https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#replace-all-repository-topics
> DATA=`jq -n \
>   --argjson topics "$$GITHUB_REPO_TOPICS" \
>   '{ names : $$topics}' \
> `
> $(CURL) \
>    -X PUT \
>   -H "Accept: application/vnd.github+json" \
>    -H "Authorization: Bearer $$GITHUB_TOKEN"\
>    https://api.github.com/repos/$${GITHUB_OWNER}/$${GITHUB_REPO}/topics \
>   --data "$$DATA" \
>   | jq .
> echo '[done]'











































.PHONY: release-packages/%
release-packages/% : packages/$$*
#* Check if environment is sufficiently defined!
> DOT_ENV=".env" && [[ -f $$DOT_ENV ]] && source $$DOT_ENV
> : $${GITHUB_OWNER:?"GITHUB_OWNER environment is required but not given"}
> : $${GITHUB_TOKEN:?"GITHUB_TOKEN environment is required but not given"}
>
> RELEASE_ASSET_DIR=$${RELEASE_ASSET_DIR:-dist}
> RELEASE_ASSET_SPECIFICATION=$${RELEASE_ASSET_SPECIFICATION:-echo none}
> GITHUB_REPO=$${GITHUB_REPO:-jq -r '.name | values' package.json}
> ASSET_PATH="./packages/$*/$${RELEASE_ASSET_DIR}"
> GITHUB_REPO_URL="https://api.github.com/repos/$${GITHUB_OWNER}/$${GITHUB_REPO}"
>
> PACKAGE_NAME=$$(jq -r '.name | values' packages/$*/package.json)
> PACKAGE_VERSION=$$(jq -r '.version | values' packages/$*/package.json)
> RELEASE_TITLE=$${PACKAGE_NAME}/v$${PACKAGE_VERSION}
>
> printf "[CONFIGURATION]\n\
[REPOSITORY] $${GITHUB_OWNER} $${GITHUB_REPO}\n\
[RELEASE] $${PACKAGE_NAME} v$${PACKAGE_VERSION}\n\
[ASSETS] $${ASSET_PATH}\n\n"
> 
> printf \
"[INFO] Checking if release $$RELEASE_TITLE already exists \n"
> USED_TAGS=$$($(CURL) \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $$GITHUB_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  $$GITHUB_REPO_URL/tags | jq -r ".[] | .name")
>
> if grep -q $$RELEASE_TITLE <<< $$USED_TAGS; then \
>   printf "[ERROR] $${RELEASE_TITLE}: Release has already been created. Aborting! \n"
>   exit 0;
> fi
> printf "[INFO] Release does not exist. \n"
> printf "[INFO] Probing Remote \n"
> kambrium.probeRemote 
#* Create new Release on Github
#* This automatically creates Release Files from Main branch
> RELEASE_PAYLOAD=`jq -n \
> --arg tag_name "$$RELEASE_TITLE" \
> --arg desc "" \
> '{tag_name: $$tag_name ,name: $$tag_name ,body: $$desc,draft: false,prerelease: false,generate_release_notes: true}'`




#>
#> RELEASE_DATA=$$($(CURL) \
#   -X POST \
#   -H "Accept: application/vnd.github+json" \
#   -H "Authorization: Bearer $${GITHUB_TOKEN}" \
#   -H "X-GitHub-Api-Version: 2022-11-28" \
#   $${GITHUB_REPO_URL}/releases \
#   -d "$${RELEASE_PAYLOAD}")
#>
#> echo $$RELEASE_DATA >> release.json
#> printf [INFO] Release has been created successfully. Attaching Files in $${ASSET_PATH} \n
#> RELEASE_ID=$$(jq -S '.id' <<< $$RELEASE_DATA)
#> 
#> RELEASE_URL="https://uploads.github.com/repos/$${GITHUB_OWNER}/$${GITHUB_REPO}/releases/$${RELEASE_ID}" 
#>
#kambrium.uploadReleaseFiles \
#   $$ASSET_PATH \
#   $$RELEASE_ASSET_SPECIFICATION \
#   $$RELEASE_URL \
#   $$GITHUB_TOKEN
