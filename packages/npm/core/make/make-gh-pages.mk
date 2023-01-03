#
# push docs package to gh-pages
# 
# Ensure the git remotes contains a connected github project having github pages enabled 
# (see https://github.com/lgersman/[your-project]/settings/pages)
# 	Source: "Deploy from branch"
# 	Branch: "None" 
#
# environment variables can be provided either by 
# 	- environment
#		- sub package `.env` file:
#		- monorepo `.env` file
#
# supported variables are : 
# 	- GIT_REMOTE_REPOSITORY_NAME (optional, default=origin)
#
#HELP: * push a single docs package to gh pages branch.\n\texample: 'GIT_REMOTE_REPOSITORY_NAME=my-origin make gh-pages-push-foo' to push docs package 'packages/docs/foo' to git remote repo with name 'my-origin'
gh-pages-push-%: packages/docs/$*/
# > @
# read .env file from package if exists 
> set -x
> DOT_ENV="packages/docs/$*/.env"; [[ -f $$DOT_ENV ]] && source $$DOT_ENV
> PACKAGE_JSON=packages/docs/$*/package.json
> GIT_REMOTE_REPOSITORY_NAME=$${GIT_REMOTE_REPOSITORY_NAME:-origin}
> GIT_REPOSITORY_URL=$$(git remote get-url --push $$GIT_REMOTE_REPOSITORY_NAME)
> # ensure we are not in branch gh-pages yet
> [[ $$(git rev-parse --abbrev-ref HEAD) == 'gh-pages' ]] && 1>&2 echo "cannot push gh-pages : current branch is gh-pages. switch to another branch and try again." && exit 1
# > # ensure there are no uncommitted changes in current branch
# > [[ -z "$(git status --porcelain)" ]] && 1>&2 echo "cannot push gh-pages : current branch contains uncommited changes. commit changes and try again." && exit 1
> # check if branch gh-pages exists on remote
> if ! git ls-remote --exit-code --heads "$$GIT_REPOSITORY_URL" gh-pages; then

# git clone /home/lgersman/workspace/pnpmkambrium
# cd pnpmkambrium/
# git switch --orphan gh-pages
# -t, --track           set upstream info for new branch
# git checkout develop .gitignore
# git status
# git reset --hard
# git commit --allow-empty -m "Initializing gh-pages branch"
# git log
# git status
# ls -la
# git status
# git add .
# git commit
# git status
# git branch
# git push
# git push --set-upstream origin gh-pages
# git branch
# xed .gitignore

# > 	PAST_BRANCH=$$(git rev-parse --abbrev-ref HEAD)
# >		# copy sub package build directory to a tempory directory
# >		TMP_DIR=$$(mktemp -d --suffix ".$@")
# >		cp -r packages/docs/$*/build $$TMP_DIR/
# >		# create or switch to local branch gh-pages and pull latest from remote gh-pages
# > 	git switch --quiet -C gh-pages || git pull $$GIT_REMOTE_REPOSITORY_NAME
# >		# delete anything in gh-stages branch
# >		rm -fr * .!(|.|git)
# >		# copy build folder into branch gh-stages
# >		mv $$TMP_DIR/ .
# see https://gist.github.com/cobyism/4730490#gistcomment-1374989
# >  and I won't have to delete the remote branch every time, which is unnecessary.
# > https://stackoverflow.com/questions/52087783/git-push-to-gh-pages-updates-were-rejected
# >		# push branch to remote 
# > 	git push $$GIT_REMOTE_REPOSITORY_NAME gh-pages:gh-pages
# > 	# switch back to previous branch
# > 	git switch $$PAST_BRANCH						
> fi
# > GITHUB_REPO_NAME="$$(\
# 		jq --exit-status -r '.repository.url | select(.!=null)' $$PACKAGE_JSON || \
# 		jq --exit-status -r '.repository.url | select(.!=null)' package.json \
# 	)"

# > echo "$$GITHUB_REPO_NAME"
# > : $${NPM_TOKEN:?"NPM_TOKEN environment is required but not given"}
# > PACKAGE_NAME=$$(jq -r '.name | values' $$PACKAGE_JSON)
# > echo "push docs package ''$$PACKAGE_NAME' to gh-pages"
# > if [[ "$$(jq -r '.private | values' $$PACKAGE_JSON)" != "true" ]]; then  
# > 	# bash does not allow declaring env variables containing "/" 
# > 	env "npm_config_$$NPM_REGISTRY:_authtoken=$$NPM_TOKEN" $(SHELL) -c "env | grep npm_ && pnpm -r --filter $$PACKAGE_NAME publish --no-git-checks"
# >		echo '[done]'
# > else
# > 	echo "[skipped]: package.json is marked as private"
# > fi