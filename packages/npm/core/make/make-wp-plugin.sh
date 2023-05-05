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
  local WP_PLUGIN_DIRECTORY="packages/wp-plugin/$(kambrium.get_sub_package_name_from_path $1)"

  find $WP_PLUGIN_DIRECTORY/src -maxdepth 1 -type f -name '*.mjs' -or -name 'block.json' | sed -e 's/src/build/g' -e 's/.mjs/.js/g'
  find $WP_PLUGIN_DIRECTORY -type f -not -path '*/tests/*' -not -path '*/dist/*' -not -path '*/build/*' -and -name '*.php' -or -name 'theme.json'
}
