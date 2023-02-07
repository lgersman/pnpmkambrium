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

#
# computes help for the Makefile
# 
# required environment variables:
#   VERBOSE(default='' is disabled)   dumps more output on stderr 
#   FORMAT(json/text,default=text)    output format. text means output send to desktop, json provides help in json format for further processing
#
# returns the computed help information
#
function kambrium:help() {
  declare -A HELP_TOPICS=()
  IFS='\n'
  # pipe all read makefiles into read loop
  while read line; do
    # if help heredoc marker matches /#\s<<([\w\:\-\_]+)/ current line 
    if [[ "$line" =~ ^#[[:blank:]]\<\<([[:print:]]+)$ ]]; then 
      HEREDOC_KEY="${BASH_REMATCH[1]}"
      declare -a HEREDOC_BODY=()
      # read lines starting with '# ' until a line containing just the heredoc token comes in 
      while read line; do
        if [[ "$line" =~ ^#[[:blank:]]$HEREDOC_KEY$ ]]; then
          # join lines separated by \n
          HEREDOC_BODY=$(printf "\n%s" "${HEREDOC_BODY[@]}")
          # strip leading \n
          HEREDOC_BODY=${HEREDOC_BODY:1}
          if [[ "$HEREDOC_BODY" == '' ]]; then
            [[ "$VERBOSE" != '' ]] && echo "[skipped] Help HereDoc(='$HEREDOC_KEY') : help body is empty" >&2
          else 
            [[ "$VERBOSE" != '' ]] && echo "'$HEREDOC_KEY'='$HEREDOC_BODY'" >&2
            # read while we match a make target
            while read line; do
              # line="$(printf '.PHONY bar\t  foo/x.txt') %.cpp :"; [[ "$line" =~ ^((([A-Za-z0-9_/.\%]+)[[:blank:]]*)+): ]] && [[ "${line::1}" != '.' ]]  && echo "matched '${BASH_REMATCH[0]}'"
              if [[ "$line" =~ ^((([A-Za-z0-9_/.\%]+)[[:blank:]]*)+): ]] && [[ "${line::1}" != '.' ]]; then
                HELP_TOPICS["${BASH_REMATCH[1]}"]="$HEREDOC_BODY"
                break
              fi 
            done
          fi
          break
        elif [[ "$line" =~ ^#[[:blank:]](([[:print:]]|[[:space:]])+)$ ]]; then
          HEREDOC_BODY+=(${BASH_REMATCH[1]})
        else
          [[ "$VERBOSE" != '' ]] && echo "[skipped] Help HereDoc(='$HEREDOC_KEY') : line '$line' does not match help line prefix(='# ') nor HereDoc end marker(='$HEREDOC_KEY')" >&2
          break
        fi
      done
    fi
  done

  if [[ "${FORMAT:-}" == 'json' ]]; then
    echo "json output selected"
  else
    echo "############## FORMAT text"
    
    for TARGET in "${!HELP_TOPICS[@]}"; do
      printf "${TARGET}:\n${HELP_TOPICS[$TARGET]}\n\n" | cat
    done    
  fi
}