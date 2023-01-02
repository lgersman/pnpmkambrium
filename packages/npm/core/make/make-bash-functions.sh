#
# returns the first parameter which is an not empty array
#
# kambrium:jq:first_non_empty_array '' 'null' '[]' '["inge"]' 'null' '["ralf","bert"]' '["sybille"]' '["kurt","fritz"]'
# => ["inge"]
#
function kambrium:jq:first_non_empty_array() {
  while test $# -gt 0
  do
      if [[ $(echo "$1" | jq '. | length') -gt 0 ]]; then 
        echo "$1"
        return 0
      fi
      shift
  done

  echo '[]'
}