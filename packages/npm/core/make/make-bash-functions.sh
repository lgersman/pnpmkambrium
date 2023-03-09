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
# renders the given markdown text into escape sequence'd text suitable for the terminal
# 
# @param $1 string markdown text 
# @return escape sequenced markdown text suitable for terminals   
#
function kambrium:render_markdown() {
  local text=$1

  # highlight text between '`'
  text=$(sed -E 's/(^|[^[:alnum:]_])`([^`]+)`([^[:alnum:]_]|$)/\1\\e[36m\2\\e[0m\3/g' <<< "$text")

  # make text between '__' bold "\e[1mbold\e[0m"
  text=$(sed -E 's/(^|[^[:alnum:]_])__([^_]+)__([^[:alnum:]_]|$)/\1\\e[1m\2\\e[0m\3/g' <<< "$text")

  # make text between '-' italic "\e[3mitalic\e[0m"
  text=$(sed -E 's/(^|[^[:alnum:]_])_([^_]+)_([^[:alnum:]_]|$)/\1\\e[3m\2\\e[0m\3/g' <<< "$text")

  # make text between '~~' strike through  "\e[9mstrikethrough\e[0m"
  text=$(sed -E 's/(^|[^[:alnum:]_])~~([^_]+)~~([^[:alnum:]_]|$)/\1\\e[9m\2\\e[0m\3/g' <<< "$text")

  # highlight markdown links and pure links between '[...]()' underline "\e[4munderline\e[0m"
  #  `(\[.*\])(\((http)(?:s)?(\:\/\/).*\))` 
  text=$(sed -E 's/(^|[^[:alnum:]_])(\[[^]]+\])?\((https?:[^)]+)\)([^[:alnum:]_]|$)/\1\\e[33m\2(\\e[0;4m\3\\e[33m)\\e[0m\4/g' <<< "$text")

  # highlight headings (#-#####) "\e[1bold\e[0m"
  text=$(sed -E 's/^(#{1,5})[[:space:]]([^$]+)$/\\e[1;34m\1 \2\\e[0m/g' <<< "$text")

  printf "%s" "$text"
}

#
# computes help for the Makefile
# 
# required environment variables:
#   VERBOSE(default='' is disabled)   dumps debugging output to stderr 
#   FORMAT(json/text,default=text)    output format. text means output send to desktop, json provides help in json format for further processing
#
# writes the computed help information to stdout
#
function kambrium:help() {
  declare -A HELP_TOPICS=()
  IFS=$'\n'
  # pipe all read makefiles into read loop
  while read line; do
    # if help heredoc marker matches /#\s<<([\w\:\-\_]+)/ current line 
    if [[ "$line" =~ ^#[[:blank:]]HELP\<\<([[:print:]]+)$ ]]; then 
      HEREDOC_KEY="${BASH_REMATCH[1]}"
      declare -a HEREDOC_BODY=()
      # read lines starting with '# ' until a line containing just the heredoc token comes in 
      while read line; do
        if [[ "$line" =~ ^#[[:blank:]]$HEREDOC_KEY$ ]]; then
          # join string array
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
              if [[ "$line" =~ ^(((([A-Za-z0-9_/.\%]|-)+)[[:blank:]]*)+): ]] && [[ "${line::1}" != '.' ]]; then
                HELP_TOPICS["${BASH_REMATCH[1]}"]="$HEREDOC_BODY"
                break
              fi 
            done
          fi
          break
        elif [[ "$line" =~ ^#[[:blank:]]?(([[:print:]]|[[:space:]])*)$ ]]; then
          HEREDOC_BODY+=(${BASH_REMATCH[1]:- })
        else
          [[ "$VERBOSE" != '' ]] && echo "[skipped] Help HereDoc(='$HEREDOC_KEY') : line '$line' does not match help line prefix(='# ') nor HereDoc end marker(='$HEREDOC_KEY')" >&2
          break
        fi
      done
    fi
  done

  # sort the HELP_TOPICS keys
  mapfile -d '' TARGETS < <(printf '%s\0' "${!HELP_TOPICS[@]}" | sort -z)
  if [[ "${FORMAT:-}" == 'json' ]]; then
    JSON='[]'
    for TARGET in "${TARGETS[@]}"; do
      # HELP_TEXT=${HELP_TEXT//$'\n'/$'\\n'}
      # HELP_TEXT=${HELP_TEXT//$'\t'/$'\\t'}

      printf -v HELP_TEXT '# %s\n\nSyntax: `make [make-options] %s [make-variables]`' "$TARGET" "$TARGET"

      [[ "$TARGET" =~ % ]] && printf -v HELP_TEXT '%s\n\n_(This is a generic target. You need to replace the %s wildcard with a existing package name.)_' "$HELP_TEXT" '`%`'

      printf -v HELP_TEXT '%s\n\n%s' "$HELP_TEXT" "${HELP_TOPICS[$TARGET]}"

      JSON=$(echo "$JSON" | jq -r \
        --arg caption "$TARGET" \
        --arg help "${HELP_TEXT}" \
        --arg prompt "make $TARGET" \
        '. += [ { "caption" : $caption, "help" : $help, "prompt" : $prompt } ]' \
      )
    done
    JSON=$JSON jq -n -r -s 'env.JSON|.'
  else 
    printf -v text '# Syntax\n\n`make [make-options] [target] [make-variables] ...`\n\n# Targets\n\n'

    if [[ "${#HELP_TOPICS[@]}" == '0' ]]; then
      printf -v text "%s_No help annotated make targets found._" "$text"
    else
      for TARGET in "${TARGETS[@]}"; do
        printf -v text '%s## %s\n\nSyntax: `make [make-options] %s [make-variables]`%s' "$text" "$TARGET" "$TARGET"

        [[ "$TARGET" =~ % ]] && printf -v text '%s\n\n_(This is a generic target. You need to replace the %s wildcard with a existing package name.)_' "$text" '`%`'

        printf -v text "%s\n\n%s\n\n" "$text" "${HELP_TOPICS[$TARGET]}"
      done
    fi

    if [[ "${FORMAT:-}" != 'markdown' ]]; then
      text=$(kambrium:render_markdown "$text")
    fi

    printf "%s" "$text"
  fi
}

#
# computes the author name by querying a priorized list of sources. 
# the first one found wins.
# 
# - environment variable AUTHOR_NAME
# - .author.name from the package.json provided as first parameter (sub package from packages/*/*/package.json)
# - .author.name from the root package.json
# - the configured git user name (git config user.name)
#
# writes the author name to stdout
#
function kambrium:author_name() {
  # assign environment variable AUTHOR_NAME or '' as fallback
  VAL=${AUTHOR_NAME:-}
  
  # if empty : try evaluating .author.name from sub package.json 
  [[ "$VAL" == '' ]] && VAL=$(jq -r '.autshor.name // ""' $1)

  # if empty : try evaluating .author.name from root package.json 
  [[ "$VAL" == '' ]] && VAL=$(jq -r '.autshor.name // ""' package.json)
  
  # if empty : try evaluating git user.name
  [[ "$VAL" == '' ]] && VAL=$(git config user.name)

  echo "$VAL"
}

