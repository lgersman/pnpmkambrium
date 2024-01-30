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
> DATA=$(jq -n \
  --arg description "$$GITHUB_REPO_DESCRIPTION" \
  --arg homepage "$$GITHUB_REPO_HOMEPAGE" \
  '{description: $$description, homepage: $$homepage })
> $(CURL) \
>    -X PATCH \
>   -H "Accept: application/vnd.github+json" \
>    -H "Authorization: Bearer $$GITHUB_TOKEN"\
>    https://api.github.com/repos/$q${GITHUB_OWNER}/$${GITHUB_REPO} \
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
> kambrium.log_done

# HELP<<EOF
# creates a GitHub release for the given package
#   - creates a GitHub release for the given package
#   - uploads the release assets
#
# supported variables are :
#   - `GITHUB_TOKEN` (required) GitHub token
#   - `GITHUB_OWNER` (required) GitHub username
#   - `GITHUB_REPO` (optional,default=property `repository.url` in root file `package.json`) GitHub repository name
#   - `RELEASE_ASSET_DIR` (optional,default=`dist`) the directory containing the release assets
#   - `RELEASE_ASSET_SPECIFICATION` (optional,default=`none`) the release asset specification
#   - `ASSET_UPLOAD` (optional,default=`true`) if set to `true` no asset upload will be performed
#
# environment variables can be provided using:
#   - make variables provided at commandline
#   - `.env` file from sub package
#   - `.env` file from monorepo root
#   - environment
#
# example: `make --silent release-packages/docs`
#   will create a GitHub release for the package `packages/docs`
# EOF
.PHONY: release-packages/%
release-packages/% : packages/$$*
#
# Check if environment is sufficiently defined!
> DOT_ENV=".env" && [[ -f $$DOT_ENV ]] && source $$DOT_ENV
>
# check environment dependencies
# GITHUB credentials
> : $${GITHUB_OWNER:?"GITHUB_OWNER environment is required but not given"}
> : $${GITHUB_TOKEN:?"GITHUB_TOKEN environment is required but not given"}
> GITHUB_REPO=$${GITHUB_REPO:-jq -r '.name | values' package.json}
> GITHUB_REPO_URL="https://api.github.com/repos/$${GITHUB_OWNER}/$${GITHUB_REPO}"
>
# Release configuration
> PACKAGE_NAME=$$(jq -r '.name | values' packages/$*/package.json)
> PACKAGE_VERSION=$$(jq -r '.version | values' packages/$*/package.json)
> RELEASE_TITLE=$${PACKAGE_NAME}/v$${PACKAGE_VERSION}
> LAST_COMMIT_SHA=$$(git rev-parse HEAD)
>
# asset configuration
> ASSET_UPLOAD=$${ASSET_UPLOAD:-"true"}
> RELEASE_ASSET_DIR=$${RELEASE_ASSET_DIR:-"dist"}
> RELEASE_ASSET_SPECIFICATION=$${RELEASE_ASSET_SPECIFICATION:-"none"}
> ASSET_PATH="./packages/$*/$${RELEASE_ASSET_DIR}"
>
# pretty print the configuration to console
> printf "[CONFIGURATION]\n\
[REPOSITORY] $${GITHUB_OWNER} $${GITHUB_REPO}\n\
[RELEASE] $${PACKAGE_NAME} v$${PACKAGE_VERSION}\n\
[ASSETS] $${ASSET_PATH}\n\n"
>
# Check if the Release tag already Exists on remote
> printf \
"[INFO] Checking if release $$RELEASE_TITLE already exists on remote "
> USED_TAGS=$$($(CURL) \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $$GITHUB_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  $$GITHUB_REPO_URL/tags | jq -r ".[] | .name")
# check if the release tag is in the list of used tags
> if grep -q $$RELEASE_TITLE <<< $$USED_TAGS; then \
>   printf "[ERROR] \n$${RELEASE_TITLE}: Release has already been created. Aborting! \n"
>   exit 0;
> fi
> printf "[SUCCESS]\n"
>
# check if release assets are synced with remote
> printf "[INFO] Probing Assets "
> kambrium.probeRemote > /dev/null 2>&1
> printf "[SUCCESS]\n"
>
# normalize assets to contain both full file path and remote file name
> kambrium.normalizeRelease $$ASSET_PATH $${RELEASE_ASSET_SPECIFICATION}
> printf "[INFO] Normalizing Assets"
> NORMALIZED_ASSETS=$$(kambrium.normalizeRelease $$ASSET_PATH $${RELEASE_ASSET_SPECIFICATION})
> printf "[SUCCESS]\n"
>
# Create empty Release on remote and get the release id
> printf "[INFO] Creating Release "
> RELEASE_PAYLOAD=`jq -n \
> --arg tag_name "$$RELEASE_TITLE" \
> --arg desc "" \
> --arg target_commit "$$LAST_COMMIT_SHA" \
> '{tag_name: $$tag_name ,"target_commitish":$$target_commit ,name: $$tag_name ,body: $$desc,draft: false,prerelease: false,generate_release_notes: true}'`
> RELEASE_DATA=$$($(CURL) \
-X POST \
-H "Accept: application/vnd.github+json" \
-H "Authorization: Bearer $${GITHUB_TOKEN}" \
-H "X-GitHub-Api-Version: 2022-11-28" \
$${GITHUB_REPO_URL}/releases \
-d "$${RELEASE_PAYLOAD}")
> printf "[SUCCESS] \n"
>
# Attach Files to Release
> RELEASE_ID=$$(jq -S '.id' <<< $$RELEASE_DATA)
> RELEASE_URL="https://uploads.github.com/repos/$${GITHUB_OWNER}/$${GITHUB_REPO}/releases/$${RELEASE_ID}"
> if [[ $$ASSET_UPLOAD == "true" ]]; then \
> printf "[INFO] Uploading Assets ";
> kambrium.ReleaseFiles \
    $$NORMALIZED_ASSETS \
    $$RELEASE_URL \
    $$GITHUB_TOKEN \
    > /dev/null 2>&1
> printf "[SUCCESS]\n" ;
> else \
> printf "[INFO] Skipping Asset Upload\n" ;
> fi
> kambrium.log_done

DOCKER_IMAGE_GITHUB_RELEASE_GH := maniator/gh
# HELP<<EOF
# creates a GitHub release and uploads the release assets
# the release tag is derived from root `package.json` property `version`
#
# supported variables are :
#   - `GITHUB_TOKEN` (required) GitHub token
#   - `GITHUB_OWNER` (required) GitHub username
#   - `GITHUB_REPO` (optional,default=property `repository.url` in root file `package.json`) GitHub repository name
#   - `GITHUB_RELEASE_ASSETS` (optional, default=all archive files in `dist` directory of public sub packages)
#
#     This variable can be used to customize the release assets.
#     `GITHUB_RELEASE_ASSETS` is expected to be a JSON array|object or a string list of release assets
#
#     - space or newline separated list of assets
#
#         example :
#         `'packages/docs/foo/dist/foo-1.0.0.zip packages/npm/a/dist/a-1.0.0.tgz packages/wp-plugin/x/dist/x-1.0.0-php7.4.zip'`
#
#     - an JSON array|object string of release assets (key=asset-name, value=asset-path)
#
#         array example :
#         `[`
#         `  "packages/docs/foo/dist/foo-1.0.0.zip",`
#         `  "packages/npm/a/dist/a-1.0.0.tgz",`
#         `  "packages/wp-plugin/x/dist/x-1.0.0-php7.4.zip"`
#         `]`
#
#         object example :
#         `[``
#         `  "foo.zip" : "packages/docs/foo/dist/foo-1.0.0.zip",`
#         `  "a archive" : "packages/npm/a/dist/a-1.0.0.tgz",`
#         `  "x.zip" : "packages/wp-plugin/x/dist/x-1.0.0-php7.4.zip"`
#         `]`
#
#     If `GITHUB_RELEASE_ASSETS` is not defined, all archive files (zip|tar.gz|tgz)
#     and executables in `packages/*/*/dist` will be used as release assets.
#
# environment variables can be provided using:
#   - make variables provided at commandline
#   - `.env` file from sub package
#   - `.env` file from monorepo root
#   - environment
#
# example: `make github-release`
#   will build outdated sub packages and create/update a GitHub release
# example: `GITHUB_RELEASE_ASSETS="$(find packages/*/*/dist -maxdepth 1 -name '*.zip')" make github-release`
#   will build outdated sub packages and create/update a GitHub release
#   All zip files in `packages/*/*/dist` will be uploaded as release assets
# EOF
.PHONY: github-release
github-release : build
> # get current branch name
> branch=$$(git rev-parse --abbrev-ref HEAD) || (
>   kambrium.log_error "failed to evaluate current git branch"
>   kambrium.log_hint "check if is current directory is a git repository."
>   kambrium.log_hint "ensure the at least one commit is available."
>   exit 1
> )
> # check current branch has tracked remote branch
> git rev-parse --abbrev-ref --symbolic-full-name "$${branch}@{u}" &> /dev/null || (
>   kambrium.log_error "current branch '$$branch' does not have a remote tracking branch"
>   kambrium.log_hint "consider pushing the current branch to remote repository to establish a remote tracking branch"
>   exit 1
> )
> # check there are no local uncommitted/untracked changes
> [[ -n $$(git status --porcelain) ]] && (
>    kambrium.log_error "there are uncommitted/untracked changes in the current branch '$$branch'"
>    kambrium.log_hint "consider committing or stashing the changes and execute target again"
>    exit 1
> )
> # check the current branch is in sync with the remote branch
> localRef=$$(git rev-parse HEAD)
> # we use this complicated looking command to (1) avoid fetching from remote repository and (2) see underlying errors in case of ssh issues
> remoteRef=$$(git -c core.sshCommand='ssh -o LogLevel=error' ls-remote $$(git rev-parse --abbrev-ref @{u} | sed 's/\// /g') | cut -f1)
> [[ $$localRef == $$remoteRef ]] || (
>   kambrium.log_error "current branch '$$branch' and remote branch are not in sync"
>   kambrium.log_hint "consider git pull/push/merge to sync local branch '$$branch' and remote branch"
>   exit 1
> )
> # get commit id of the release tag matching the current package.json name and version
> release_commit=$$(git rev-list -n 1 "$$(jq -r '.name | values' package.json)@$$(jq -r '.version | values' package.json)") || (
>   kambrium.log_error "failed to get commit id of release tag '$$(jq -r '.name | values' package.json)@$$(jq -r '.version | values' package.json)' matching the current package.json name and version"
>   kambrium.log_hint "tag the current commit as release using 'pnpm changeset tag'"
> )
> # retrieve git tags on this commit (=> they describe which sub packages were released)
> # - root package tag gets strip (using grep) from the list of tags
> # - strip the version suffix from the tag (using sed)
> packageReleases=$$(git tag --points-at $$release_commit | grep -E '^@' | sed 's/@[^@]*$$//' | sort)
> NL=$$'\n'
> # put changes in root CHANGELOG.md on top of RELEASE_NOTES
> RELEASE_NOTES="$$(git diff $${release_commit}~1 $$release_commit -- 'CHANGELOG.md' | tail -n +7 | cut -c2-)$${NL}"
> # iterate over package releases
> while read -r packageRelease; do
>   # get the path of the package
>   # alternatively : $(PNPM) list --json --recursive --only-projects | jq -r ".[] | select(.name==\"$$packageRelease\").path"
>   packagePath=$$(realpath --relative-to=$$(pwd) ./node_modules/$$packageRelease)
>   # get changed lines from changelog
>   # - strip the first 6 lines using tail)
>   # - strip the first character (+|-) using cut
>   changedLines=$$(git diff $${release_commit}~1 $$release_commit -- "$$packagePath/CHANGELOG.md" | tail -n +7 | cut -c2-)
>   # if changedLines is empty => no changes in CHANGELOG.md => no package publish
>   if [[ "$$changedLines" != '' ]]; then
>     RELEASE_NOTES="$${RELEASE_NOTES}$${NL}$$changedLines$${NL}"
>      # @TODO: collect release assets from sub packages
>   fi
>     # TODO: compute CHANGELOG by concatenating CHANGELOG.md files from sub packages
>     # @TODO: collect release assets from sub packages
> done < <(echo "$$packageReleases")
>
> echo "$$RELEASE_NOTES"
>
> # docker run -it --rm -v $(HOME):/root -v $$(pwd):/gh $(DOCKER_FLAGS) $(DOCKER_IMAGE_GITHUB_RELEASE_GH)
> # @TODO: add changelog/release-readme parameter and how to compute it
> # see https://docs.github.com/en/rest/releases/releases?apiVersion=2022-11-28#generate-release-notes-content-for-a-release
> # see https://github.com/evanw/esbuild/blob/main/Makefile
