#
# common bash functions automatically injected in our make SHELL  
#

#
# computes the author name by querying a priorized list of sources. 
# the first one found wins.
# 
# - environment variable AUTHOR_NAME
# - .author.name from the package.json provided as parameter $1 (sub package from packages/*/*/package.json)
# - .author.name from the root package.json
# - the configured git user name (git config user.name)
#
# @param $1 path to package.json 
# @return the first found author or an empty string if not found
#
function kambrium:author_name() {
  # assign environment variable AUTHOR_NAME or '' as fallback
  VAL=${AUTHOR_NAME:-}
  
  # if empty : try evaluating .author.name from sub package.json 
  [[ "$VAL" == '' ]] && VAL=$(jq -r '.author.name // ""' $1)

  # if empty : try evaluating .author.name from root package.json 
  [[ "$VAL" == '' ]] && VAL=$(jq -r '.author.name // ""' package.json)
  
  # if empty : try evaluating git user.name
  [[ "$VAL" == '' ]] && VAL=$(git config user.name)

  echo "$VAL"
}

#
# computes the author email by querying a priorized list of sources. 
# the first one found wins.
# 
# - environment variable AUTHOR_EMAIL
# - .author.email from the package.json provided as first parameter (sub package from packages/*/*/package.json)
# - .author.email from the root package.json
# - the configured git user email (git config user.email)
#
# writes the author email to stdout
#
function kambrium:author_email() {
  # assign environment variable AUTHOR_EMAIL or '' as fallback
  VAL=${AUTHOR_EMAIL:-}
  
  # if empty : try evaluating .author.email from sub package.json 
  [[ "$VAL" == '' ]] && VAL=$(jq -r '.author.email // ""' $1)

  # if empty : try evaluating .author.email from root package.json 
  [[ "$VAL" == '' ]] && VAL=$(jq -r '.author.email // ""' package.json)
  
  # if empty : try evaluating git user.email
  [[ "$VAL" == '' ]] && VAL=$(git config user.email)

  echo "$VAL"
}