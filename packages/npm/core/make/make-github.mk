# contains github related targets

#
# update informational github repo 
#		- update repo description from root package.json
#		- update repo tags
#		- enable github pages to if a docs sub package 'gh-pages' exists
# 
# environment variables can be provided either by 
# 	- environment
#		- sub package `.env` file:
#		- monorepo `.env` file
#
# supported variables are : 
# 	- GITHUB_TOKEN (required) can be the github password (a github token is preferred for security reasons)
# 	- GITHUB_USER (required) github username 
# 	- GITHUB_REPOSITORY (optional,default=root package.json name) GitHub repository name
#
# test using `GITHUB_TOKEN="foo" GITHUB_USER="bar" make --silent github-update-docs`

.PHONY: github-update-docs
#HELP: * update github repo documentation.\n\texample: 'GIT_REMOTE_REPOSITORY_NAME=my-origin make gh-pages-push-foo' to push 'build' folder contents of docs package 'packages/docs/foo' to git remote repo with name 'my-origin'
github-update-docs: $(wildcard packages/docs/gh-pages/)
> # $(wildcard packages/docs/gh-pages/) dont fail of packages/docs/gh-pages/ doesnt exist
> # https://docs.github.com/en/rest/overview/resources-in-the-rest-api?apiVersion=2022-11-28#user-agent-required
> # https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28
> # https://gist.github.com/btoone/2288960
# abort if GITHUB_TOKEN is not defined
> : $${GITHUB_TOKEN:?"GITHUB_TOKEN environment is required but not given"}
# abort if GITHUB_USER is not defined
> : $${GITHUB_USER:?"GITHUB_USER environment is required but not given"}
> # read .env file from package if exists
> DOT_ENV="packages/docs/$*/.env"; [[ -f $$DOT_ENV ]] && source $$DOT_ENV
> GITHUB_REPOSITORY=$${GITHUB_REPOSITORY:-$$(jq -r '.name | values' package.json)}
> echo "GITHUB_REPOSITORY=$$GITHUB_REPOSITORY"
> echo "GITHUB_REPOSITORY=$$(printenv GITHUB_TOKEN)"
> echo "GITHUB_USER=$$(printenv GITHUB_USER)"
# if sub package gh-pages exists
>	if [[ "$^" != '' ]]; then
>		echo "dependencies are '$^'"
> else 
>		echo "sub package gh-pages doenst exist"
> fi