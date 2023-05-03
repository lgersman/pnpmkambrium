# wordpress plugin related shell helper functions

#
# computes the pot path from the po path containing the locale
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
