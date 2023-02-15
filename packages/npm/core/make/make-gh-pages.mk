#
# HELP<<EOF
# pushes a single docs sub package `build` directory output to git branch `gh-pages`. 
#
#	it the docs package is outdated, it will be rebuild before publishing.
# 
# after initial call to this target ensure the connected remote github repo has github pages properly configured
# (see https://github.com/lgersman/[your-project]/settings/pages)
# 	Source: `Deploy from branch`
# 	Branch: `gh-pages` / `/` (root folder in branch `gh-pages`)
#
# supported variables are : 
# 	- `GIT_REMOTE_REPOSITORY_NAME` (optional, default=`origin`) the remote repository to push to
#
#		if the target repo is at GitHub: 
# 		- `GITHUB_TOKEN` (required) can be the github password (a github token is preferred for security reasons)
# 		- `GITHUB_OWNER` (required) github username 
# 		- `GITHUB_REPO` (optional,default=property `repository.url` in root file `package.json`) GitHub repository name
#
# environment variables can be provided using:
# 	- make variables provided at commandline
#		- `.env` file from sub package
#		- `.env` file from monorepo root
# 	- environment
#
#	example: `make gh-pages-push-gh-pages GITHUB_OWNER=foo GITHUB_TOKEN=bar` 
#
#		will publish the build output of docs sub package `gh-pages` located in `packages/docs/gh-pages` to 
# 	the GitHub repository (annotated in property `repository.url` in root file `package.json`).
#
# EOF
.PHONY: gh-pages-push-%
gh-pages-push-%: packages/docs/$$*/
> # read .env file from package if exists
> DOT_ENV="packages/docs/$*/.env"; [[ -f $$DOT_ENV ]] && source $$DOT_ENV
> PACKAGE_JSON=packages/docs/$*/package.json
> echo "update gh-pages branch using packages/docs/$*/build"
> if [[ "$$(jq -r '.private | values' $$PACKAGE_JSON)" != "true" ]]; then 
> 	PACKAGE_VERSION=$$(jq -r '.version | values' $$PACKAGE_JSON)
> 	GIT_REMOTE_REPOSITORY_NAME=$${GIT_REMOTE_REPOSITORY_NAME:-origin}
> 	# ensure we are not in branch gh-pages yet
> 	[[ $$(git rev-parse --abbrev-ref HEAD) == 'gh-pages' ]] && echo "cannot push gh-pages : current branch is gh-pages. switch to another branch and try again." >&2 && exit 1
# > 	# ensure there are no uncommitted changes in current branch
# > 	[[ -z "$(git status --porcelain)" ]] && echo "cannot push gh-pages : current branch contains uncommited changes. commit changes and try again." >&2 && exit 1
> 	# ensure our (potential existing) temp directory gets removed after this make target  
> 	trap 'rm -rf "$(KAMBRIUM_TMPDIR)/$@"; exit' EXIT
> 
> 	# fetch gh-pages branch if exists on remote
> 	git ls-remote --exit-code --heads "$$GIT_REMOTE_REPOSITORY_NAME" gh-pages >/dev/null && git fetch "$$GIT_REMOTE_REPOSITORY_NAME" gh-pages:gh-pages
> 	if git show-branch gh-pages &> /dev/null; then
> 		# clone only branch gh-pages without any checked out files (-n) 
> 		git clone -q -b gh-pages -n file://$(CURDIR) --depth 1 "$(KAMBRIUM_TMPDIR)/$@" >/dev/null
> 	else
>			( 
>				# cd command will only affect commands in subshell
> 			cd "$(KAMBRIUM_TMPDIR)"
> 			# clone project repo with minimal git history (--depth 1) and without any checked out contents (-n)
> 			git clone -q -n file://$(CURDIR) --depth 1 "$(KAMBRIUM_TMPDIR)/$@" && cd $$_
> 			# create a new branch gh-pages with a detached history (--orphan)
> 			git switch --orphan gh-pages  &> /dev/null
>				git commit --allow-empty -m "Initializing gh-pages branch" >/dev/null
> 		)
> 	fi
> 
> 	# add builded doc output to gh-branch in KAMBRIUM_TMPDIR)/$@ and sync it back to our repo 
> 	(	
> 		SHORT_COMMIT_HASH=$$(git rev-parse --short HEAD)
>   	cd "$(KAMBRIUM_TMPDIR)/$@/"  
> 		# copy all (including hidden) files recursive to cloned repo 
> 		cp -r "$(CURDIR)/packages/docs/$*/build/." ./
> 		git add .
> 		# git commit will result in exitcode != 0 if nothing to commit but we need to call exit 1 explicitly since the subshell would not abort by default
> 		git commit -m "deploy: #$$SHORT_COMMIT_HASH sub package $* version $$PACKAGE_VERSION" >/dev/null || exit 1
> 		# push back changes to project repo
>   	git push --set-upstream $$GIT_REMOTE_REPOSITORY_NAME gh-pages &> /dev/null
>		) || { 
> 		# if commit was empty and exit 1 was executed we will land here 			
> 		echo "[skipped]: nothing changed" 
>			exit 
>		}
> 	# push local updated gh-pages branch back back to remote repo
>		git push origin gh-pages:gh-pages &> /dev/null
> 	echo '[done]'
> 
> 	if [[ "$${GITHUB_TOKEN:-}" != '' ]]; then
> 		# configure/enable GitHub pages 
> 		echo "configure/enable GitHub Pages to use branch 'gh-pages'"
> 		# see https://docs.github.com/en/rest/pages?apiVersion=2022-11-28#update-information-about-a-github-pages-site
> 		GITHUB_REPO=$${GITHUB_REPO:-$$(jq -r '.name | values' package.json)}
> 		: $${GITHUB_OWNER:?"GITHUB_OWNER environment is required but not given"}
>			DATA='{"source":{"branch":"gh-pages","path":"/"}}'
>			echo "$$DATA"
> 		HTTP_STATUS=`$(CURL) \
>  			-X PUT \
> 			-H "Accept: application/vnd.github+json" \
>  			-H "Authorization: Bearer $$GITHUB_TOKEN"\
>				-w '%{http_code}' \
>  			https://api.github.com/repos/$${GITHUB_OWNER}/$${GITHUB_REPO}/pages \
> 			--data "$$DATA" \
>			`
>			if [[ "$$HTTP_STATUS" == '204' ]]; then 
> 			$(CURL) \
> 				-H "Accept: application/vnd.github+json" \
>  				-H "Authorization: Bearer $$GITHUB_TOKEN"\
>  				https://api.github.com/repos/$${GITHUB_OWNER}/$${GITHUB_REPO}/pages \
>				| jq '{ source }'
> 			echo '[done]'
>			else 
>				echo '[error] : Failed to update GitHub Pages configuration (http status=$$HTTP_STATUS)'
>				exit 1
>			fi
> 	fi
>
> else
> 	echo "[skipped]: package.json is marked as private"
> fi