# contains github related targets

#
# update informational github repo 
#		- update repo description and tags from root package.json
#		- enable github pages if a docs sub package packages/docs/gh-pages exists and packages/docs/gh-pages/package.json property 'private' is falsy
# 
# environment variables can be provided either by 
# 	- environment
#		- sub package `.env` file:
#		- monorepo `.env` file
#
# supported variables are : 
# 	- GITHUB_TOKEN (required) can be the github password (a github token is preferred for security reasons)
# 	- GITHUB_OWNER (required) github username 
# 	- GITHUB_REPO (optional,default=root package.json name) GitHub repository name
#		- GITHUB_REPO_DESCRIPTION (optional,default=value of root package.json property 'description')
# 	- GITHUB_REPO_TOPICS (optional,default=value of root package.json property 'keys')
# 	- GITHUB_REPO_HOMEPAGE (optional,default=value of root package.json property 'homepage')
#
# test using `GITHUB_TOKEN="foo" GITHUB_OWNER="bar" make --silent github-details-push`
.PHONY: github-details-push
#HELP: * update github repo documentation.\n\texample: 'GIT_REMOTE_REPOSITORY_NAME=my-origin make gh-pages-push-foo' to push 'build' folder contents of docs package 'packages/docs/foo' to git remote repo with name 'my-origin'
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
# if sub package 'gh-pages' exists
>	if [[ "$^" != '' ]]; then
>		echo "dependencies are '$^'"
> else 
>		[ ! -f packages/docs/gh-pages/package.json ] && echo "[skipped]: packages/docs/gh-pages/ is marked as private"
>		echo "sub package gh-pages doenst exist"
> fi
> # update description and homepage
> DATA=`jq -n \
> 	--arg description "$$GITHUB_REPO_DESCRIPTION" \
>   --argjson topics "$$GITHUB_REPO_TOPICS" \
>   --arg homepage "$$GITHUB_REPO_HOMEPAGE" \
> 	'{description: $$description, homepage: $$homepage, topics: $$topics}' \
> `
> jq . <(echo $$DATA)
>	echo $$DATA | curl -s --show-error \
>		--fail \
>  	-X PATCH \
> 	-H "Accept: application/vnd.github+json" \
>  	-H "Authorization: Bearer $$GITHUB_TOKEN"\
>  	https://api.github.com/repos/$${GITHUB_OWNER}/$${GITHUB_REPO} \
> 	--data-binary @- \
> 	| jq .
> echo '[done]'
