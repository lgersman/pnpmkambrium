# we need to verify, that the remote and local git share the same files.
# GitHub will not allow to create a empty release and will always attach the remote repository
# as a zip and a tar file. to ensure that assets and repository are created similarly we need to probe them.
#  - check if the local branch has a remote tracking branch
#  - check if there are any uncommitted files
#  - check if there are local commits that are not on the remote
#  - check if there are remote commits that are not on the local branch
#
# Returns:
# - 0 if all checks passed
# - 1 if any of the checks failed
function kambrium.probeRemote() {
    local branch=$(git rev-parse --abbrev-ref HEAD)

    # Check if the current branch has a remote tracking branch
    # if not, we can not create a release since there is no remote repository to release from
    if ! git rev-parse --abbrev-ref --symbolic-full-name "$branch@{u}" &> /dev/null; then
        printf "[ERROR] The current branch '%s' does not have a remote tracking branch.\n" "$branch"
        return 1
    fi

    # Check if there are any uncommitted files
    # if there are, remote and local repository are not in sync
    if [ -n "$(git status --porcelain)" ]; then
        printf "[ERROR] There are uncommitted files in the repository for branch '%s'.\n" "$branch"
        return 1
    fi

    # fetch the delta between the local and remote repository
    # if either of them is greater than 0, the repositories are not in sync
    local local_commits=$(git rev-list --count "$branch".."origin/$branch")
    local remote_commits=$(git rev-list --count "origin/$branch".."$branch")

    if [ "$local_commits" -lt $remote_commits ]; then
        printf "[ERROR] There are local commits that are not on the remote for branch '%s'.\n" "$branch"
    elif [ "$local_commits" -gt $remote_commits ]; then
        printf "[ERROR] There are remote commits that are not on the local branch '%s'.\n" "$branch"
    fi

    printf "[INFO] All checks passed for branch '%s'.\n" "$branch"
}

# Normalize the release assets
# we can either provide them as a object, array or as a empty string
# if we provide a empty string, we will fetch all files in the dist folder
# and use them as assets
#  - convert a distSpecification object to a object with the full filename as key and the assetname as value
#  - convert a distSpecification array to a object with the full filename as key and the assetname as value
#  - provide the option to fetch all files in the dist folder and use them as assets if distSpecification is "none"
#
# Arguments:
# - distDir: the directory where the assets are located
# - distSpecification: a object, array or empty string
#
# Returns:
# - 0 if the assets were normalized successfully
# - 1 if the distSpecification could not be normalized
kambrium.normalizeRelease () {
    local distDir="$1"
    local distSpecification="$2"
    local normalizedAssets=$(echo '{}' | jq -c '.')

    # check if the dist folder even exists
    # if not, we can not create a release
    if [ ! -d "$distDir" ]; then
        echo "[ERROR] Dist Folder does not exist!"
        return 2
    fi

    # check if the distSpecification is empty
    # if it is, we will fetch all files in the dist folder and use them as assets
    # using the filename as the assetname
    if [ "$distSpecification" == "none" ]; then
        local foundAssets=$(find $distDir -maxdepth 1 -type f)
        # iterate over the found assets and create a object with the filename as key and value
        # we need to use jq to create a valid json object
        for asset in $foundAssets ; do
            local filename=$(basename "$asset")
            normalizedAssets=$(echo "$normalizedAssets" | jq -c --arg key "$asset" --arg value "$filename" '. + { ($key): $value }')
        done
        echo $normalizedAssets
        return 0;
    fi
    # check if the distSpecification is a object or array
    # the distSpecification can be a object, array or a empty string
    # we normalize the specification to a object to ensure that we can iterate over it
    # and that we can store the filename as key and the assetname as value
    local specType=$(echo $distSpecification | jq -c -r type)

    # Normalize Objects to better Objects
    # filename = distDir + filename
    # assetname = assetname
    if [ "$specType" == "object" ]; then
        normalizedAssets=$(echo "$distSpecification" | jq -c --arg prefix "$distDir/" 'to_entries | map({("\($prefix)\(.key)"): .value}) | add')
        kambrium.verifyAsset $normalizedAssets
        echo $normalizedAssets
        return 0;

    # Normalize Arrays to Objects
    # filename = distDir + filename
    # assetname = basename(filename)
    elif [ "$specType" == "array" ]; then
        normalizedAssets=$(echo "$distSpecification" | jq -R -c --arg fixed "$distDir/" 'fromjson | map({($fixed + sub(".*/"; "")): sub(".*/"; "")}) | add')
        kambrium.verifyAsset $normalizedAssets
        echo $normalizedAssets

        return 0;
    fi
    # if the distSpecification is not a object or array, we can not normalize it
    # and we will return a error
    return 1
}

# Create a new release on GitHub
#  - attach the release assets to the release
#
# Arguments:
# - distSpecification: a object, array or empty string
# - releaseURL: the url to the release
# - token: the GitHub token
#
# Returns:
# - 0 if all files were attached successfully
function kambrium.ReleaseFiles () {
    local distSpecification=$1
    local releaseURL=$2
    local token=$3

    kambrium.verifyAsset $distSpecification

    # using jq, grab every key from a object and iterate over it
    local assets=$(jq -r 'keys[]' <<< "$distSpecification")
    for asset in $assets; do
      local assetname=$(echo "$distSpecification" | jq -r --arg key "$asset" '.[$key]')
      printf "[INFO] attaching $(basename $asset) as $assetname "
      curl -s --show-error --fail-with-body\
      -X POST \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer $token"\
      -H "X-GitHub-Api-Version: 2022-11-28" \
      -H "Content-Type: application/octet-stream" \
      "$releaseURL/assets?name=$assetname" \
      --data-binary "@$asset" >> /dev/null
      printf "[SUCCESS] \n"
    done

    # TODO: check if the asset was attached successfully
    # if not, we need to abort the release
    # if [ $? -ne 0 ]; then
    #     printf "[ERROR] Failed to attach asset '%s' to release '%s'.\n" "$asset" "$releaseURL"
    #     return 1
    # fi
    return 0
}


# verify that a asset inside the release specification exists
#  - check if the asset exists
#  - check if the asset is a file
#  - check if the asset is not empty
#
# Arguments:
# - distSpecification: normalized distSpecification object with key = path and value = assetname
#
# Returns:
# - 0 if all assets exist
# - 1 if a asset does not exist
# - 2 if a asset is empty
kambrium.verifyAsset () {

    local distSpecification="$1"

    # using jq, grab every key from a object and iterate over it
    local assets=$(jq -r 'keys[]' <<< "$distSpecification")
    for asset in $assets; do
      local assetname=$(echo "$distSpecification" | jq -r --arg key "$asset" '.[$key]')
      # check if the asset exists and is a file
      if [ ! -f "$asset" ]; then
          printf "[ERROR] Asset '%s' does not exist.\n" "$asset"
          return 1
      fi
      # check if the asset is empty
      if [ ! -s "$asset" ]; then
          printf "[ERROR] Asset '%s' is empty.\n" "$asset"
          return 2
      fi
    done
    return 0
}
