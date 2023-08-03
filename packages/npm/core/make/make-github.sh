
function kambrium.uploadReleaseFiles ()
{
    local distDir=$1
    local distSpecification=$2
    local releaseURL=$3
    local token=$4

    if [ ! -d "$distDir" ]; then
        echo [INFO] Dist Folder does not exist!
        return 0
    fi

    if [[ $(echo "$distSpecification" | jq -e 'select(. | type == "object")') ]]; then
    echo "Object" ;
    elif [[ $(echo "$distSpecification" | jq -e 'select(. | type == "array")') ]]; then
    echo "Array" ;
    else
    kambrium.releasewithoutSpecification $distDir $releaseURL $token
    fi
}

function kambrium.releasewithoutSpecification () 
{
    local distDir="$1"
    local releaseURL="$2"
    local token="$3"
    local assets=$(find $distDir -maxdepth 1 -type f )

    echo $assets

    for asset in $assets; do
        echo [INFO] attaching File: $asset ; \
        curl -s --show-error --fail-with-body\
        -X POST \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer $token"\
        -H "X-GitHub-Api-Version: 2022-11-28" \
        -H "Content-Type: application/octet-stream" \
        "$releaseURL/assets?name=$(basename $asset)" \
        --data-binary "@$asset" >> /dev/null
    done
}


function kambrium.probeRemote() {
    local branch=$(git rev-parse --abbrev-ref HEAD)

    # Check if the current branch has a remote tracking branch
    if ! git rev-parse --abbrev-ref --symbolic-full-name "$branch@{u}" &> /dev/null; then
        printf "Error: The current branch '%s' does not have a remote tracking branch.\n" "$branch"
        return 1
    fi

    # Check if there are any local commits that are not on the remote
    if git log "$branch..$branch@{u}" &> /dev/null; then
        printf "Error: There are local commits that are not on the remote for branch '%s'.\n" "$branch"
        return 1
    fi

    # Check if there are any uncommitted files
    if [ -n "$(git status --porcelain)" ]; then
        printf "Error: There are uncommitted files in the repository for branch '%s'.\n" "$branch"
        return 1
    fi

    printf "All checks passed for branch '%s'.\n" "$branch"
}
