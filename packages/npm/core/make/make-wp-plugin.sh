# wordpress plugin related shell helper functions

#
# computes the i18n pot path from the i18n po path containing the locale
#
# example:
#   kambrium.get_pot_path "packages/wp-plugin/cm4all-wp-impex/languages/cm4all-wp-impex-en_US.po"
#   => "packages/wp-plugin/cm4all-wp-impex/languages/cm4all-wp-impex.pot"
#
# @param $1 the po path containing the locale
# @return the computed pot path
#
function kambrium.get_pot_path() {
  local po_path="$1"
  local locale=$([[ "$po_path" =~ ([a-z]+_[A-Z]+)\.po$ ]] && echo ${BASH_REMATCH[1]})
  echo "${po_path%?$locale.*}.pot"
}

#
# computes the makefile dependencies for a i18n pot file
#
# example:
#   kambrium.get_pot_path "packages/wp-plugin/cm4all-wp-impex/languages/cm4all-wp-impex-en_US.po"
#   => "packages/wp-plugin/cm4all-wp-impex/languages/cm4all-wp-impex.pot"
#
# @param $1 the plugin directory
# @return the computed dependencies
#
function kambrium.get_pot_dependencies() {
  local WP_PLUGIN_DIRECTORY="packages/$(kambrium.get_sub_package_type_from_path $1)/$(kambrium.get_sub_package_name_from_path $1)"

  find $WP_PLUGIN_DIRECTORY/src -maxdepth 1 -type f -name '*.mjs' -or -name 'block.json' | sed -e 's/src/build/g' -e 's/.mjs/.js/g'
  find $WP_PLUGIN_DIRECTORY -type f -not -path '*/tests/*' -not -path '*/dist/*' -not -path '*/build/*' -and -name '*.php' -or -name 'theme.json'
}

#
# computes the plugin metadata like authors and stuff and exposes them as exports
#
# example:
#   kambrium.get_wp_plugin_metadata "packages/wp-plugin/cm4all-wp-impex"
#
# @param $1 the plugin directory
# @return the names of all exported variables
#
function kambrium.get_wp_plugin_metadata() {
  local CURRENT_ALLEXPORT_STATE="$(shopt -po allexport)"
  set -a
  local WP_PLUGIN_DIRECTORY="packages/$(kambrium.get_sub_package_type_from_path $1)/$(kambrium.get_sub_package_name_from_path $1)"
  # inject sub package environments from {.env,.secrets} files
  kambrium.load_env "$WP_PLUGIN_DIRECTORY"
  PACKAGE_JSON="$WP_PLUGIN_DIRECTORY/package.json"
  PACKAGE_VERSION=$(jq -r '.version | values' $PACKAGE_JSON)
  PACKAGE_AUTHOR="$(kambrium.author_name $PACKAGE_JSON) <$(kambrium.author_email $PACKAGE_JSON)>"
  FQ_PACKAGE_NAME=$(jq -r '.name | values' $PACKAGE_JSON | sed -r 's/@//g')
  PACKAGE_NAME=${FQ_PACKAGE_NAME#*/}
  HOMEPAGE=${HOMEPAGE:-$(jq -r -e '.homepage | values' $PACKAGE_JSON || jq -r '.homepage | values' package.json)}
  DESCRIPTION=${DESCRIPTION:-$(jq -r -e '.description | values' $PACKAGE_JSON || jq -r '.description | values' package.json)}
  TAGS=${TAGS:-$(jq -r -e '.keywords | values | join(", ")' $PACKAGE_JSON || jq -r '.keywords | values | join(", ")' package.json)}
  PHP_VERSION=${PHP_VERSION:-$(jq -r -e '.config.php_version | values' $PACKAGE_JSON || jq -r '.config.php_version | values' package.json)}
  WORDPRESS_VERSION=${WORDPRESS_VERSION:-$(jq -r -e '.config.wordpress_version | values' $PACKAGE_JSON || jq -r '.config.wordpress_version | values' package.json)}
  AUTHORS="${AUTHORS:-[]}"
  [[ "$AUTHORS" == '[]' ]] && AUTHORS=$(jq '[.contributors[]? | .name]' $PACKAGE_JSON)
  [[ "$AUTHORS" == '[]' ]] && AUTHORS=$(jq '[.author.name | select(.|.!=null)]' $PACKAGE_JSON)
  [[ "$AUTHORS" == '[]' ]] && AUTHORS=$(jq '[.contributors[]? | .name]' package.json)
  [[ "$AUTHORS" == '[]' ]] && AUTHORS=$(jq '[.author.name | select(.|.!=null)]' package.json)
  # if AUTHORS looks like a json array ([.*]) transform it into a comma separated list
  if [[ "$AUTHORS" =~ ^\[.*\]$ ]]; then
    AUTHORS=$(echo "$AUTHORS" | jq -r '. | values | join(", ")')
  fi
  VENDOR=${VENDOR:-}
  LICENSE=$(\
    jq -r -e 'if (.license | type) == "string" then .license else .license.type end | values' $PACKAGE_JSON || \
    jq -r -e 'if (.license | type) == "string" then .license else .license.type end | values' package.json || \
    true \
  )
  LICENSE_URI=$(\
    jq -r -e '.license.uri | values' $PACKAGE_JSON 2>/dev/null || \
    jq -r -e '.license.uri | values' package.json 2>/dev/null || \
    [[ "$LICENSE" != "" ]] && echo "https://opensource.org/licenses/$LICENSE" || \
    true \
  )

  local NAMES=( \
    PACKAGE_JSON \
    PACKAGE_VERSION \
    PACKAGE_AUTHOR \
    FQ_PACKAGE_NAME \
    PACKAGE_NAME \
    HOMEPAGE \
    DESCRIPTION \
    TAGS \
    PHP_VERSION \
    WORDPRESS_VERSION \
    AUTHORS \
    VENDOR \
    LICENSE \
    LICENSE_URI \
  )

  # print names each on a new line
  NAMES=$(printf "\n%s" "${NAMES[@]}")
  echo "${NAMES:1}"

  # restore the value of allexport option to its original value.
  eval "$CURRENT_ALLEXPORT_STATE" >/dev/null
}
