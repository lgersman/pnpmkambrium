# contains GitHub related targets

# HELP<<EOF
# syncs informational data like description/tags/etc. to GitHub repository metadata  
#		- sync repo description and tags from root file `package.json`
#		- enable GitHub pages if a docs sub package `'packages/docs/gh-pages'` exists and `'packages/docs/gh-pages/package.json'` property 'private' is falsy
# 
# supported variables are : 
# 	- `GITHUB_TOKEN` (required) can be the GitHub password (a GitHub token is preferred for security reasons)
# 	- `GITHUB_OWNER` (required) GitHub username 
# 	- `GIT_REMOTE_REPOSITORY_NAME` (optional, default=`origin`) the remote repository to push to
# 	- `GITHUB_REPO` (optional,default=property `'repository.url'` in root file `'package.json'`) GitHub repository name
#		- `GITHUB_REPO_DESCRIPTION` (optional,default=property `'description'` in root file `'package.json'`)
# 	- `GITHUB_REPO_TOPICS` (optional,default=property `'keys'` in root file `'package.json'`)
# 	- `GITHUB_REPO_HOMEPAGE` (optional,default=property `'homepage'` in root file `'package.json'`)
#
# environment variables can be provided using:
# 	- make variables provided at commandline
#		- `'.env'` file from sub package
#		- `'.env'` file from monorepo root
# 	- environment
#
# example: `make --silent github-details-push`
#		
#		will update the GitHub repository metadata with the provided data
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
> # read .env file from package if exists
> DOT_ENV="packages/docs/$*/.env"; [[ -f $$DOT_ENV ]] && source $$DOT_ENV
> PACKAGE_NAME=$$(jq -r '.name | values' package.json)
> GITHUB_REPO=$${GITHUB_REPO:-$$PACKAGE_NAME}
> GITHUB_REPO_DESCRIPTION=$${GITHUB_REPO_DESCRIPTION:-$$(jq --exit-status -r '.description | values' package.json)}
> GITHUB_REPO_TOPICS=$${GITHUB_REPO_TOPICS:-$$(jq --exit-status '.keywords' package.json || echo '[]')}
> GITHUB_REPO_HOMEPAGE=$${GITHUB_REPO_HOMEPAGE:-$$(jq -r --exit-status '.homepage | values' package.json)}
> echo "push '$$PACKAGE_NAME' github repo details"
> # update description and homepage
> DATA=`jq -n \
> 	--arg description "$$GITHUB_REPO_DESCRIPTION" \
>   --arg homepage "$$GITHUB_REPO_HOMEPAGE" \
> 	'{description: $$description, homepage: $$homepage }' \
> `
> echo "$$DATA" && $(CURL) \
>  	-X PATCH \
> 	-H "Accept: application/vnd.github+json" \
>  	-H "Authorization: Bearer $$GITHUB_TOKEN"\
>  	https://api.github.com/repos/$${GITHUB_OWNER}/$${GITHUB_REPO} \
> 	--data "$$DATA" \
> 	| jq '{ description, homepage }'
> # update topics
> # Note: To edit a repository's topics, use the Replace all repository topics endpoint.
> # https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#replace-all-repository-topics
> DATA=`jq -n \
>   --argjson topics "$$GITHUB_REPO_TOPICS" \
> 	'{ names : $$topics}' \
> `
> echo "$$DATA" && $(CURL) \
>  	-X PUT \
> 	-H "Accept: application/vnd.github+json" \
>  	-H "Authorization: Bearer $$GITHUB_TOKEN"\
>  	https://api.github.com/repos/$${GITHUB_OWNER}/$${GITHUB_REPO}/topics \
> 	--data "$$DATA" \
> 	| jq .
> echo '[done]'
