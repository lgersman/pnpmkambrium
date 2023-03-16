#!/usr/bin/env bash

#
# this file acts as our bash shell wrapper featuring 
# - auto injected bash libraries
# - debug instrumentation
# 
# see https://github.com/lgersman/make-auto-import-bash-library-using-shell-wrapper-demo/ for inspiration 
#

# enable bash "strict mode"
set -e -u -o pipefail

# The name of this present script:
readonly SELFNAME="${BASH_SOURCE[0]##*/}"

main() {
  local preloads=() always_preloads=() prologues=() always_prologues=()
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --preload)
        preloads+=("${2:?"missing argument to $1"}")
        shift 2
        ;;
      --always-preload)
        always_preloads+=("${2:?"missing argument to $1"}")
        shift 2
        ;;
      --prologue)
        prologues+=("${2:?"missing argument to $1"}")
        shift 2
        ;;
      --always-prologue)
        always_prologues+=("${2:?"missing argument to $1"}")
        shift 2
        ;;
      --xtrace)        
        KAMBRIUM_SHELL_XTRACE=("${2:?"missing argument to $1"}")
        if [[ "$KAMBRIUM_SHELL_XTRACE" == 'true' ]]; then
          echo >&2 "KAMBRIUM_SHELL_XTRACE is set: activating xtrace."
          PS4='+${BASH_SOURCE[0]}:${LINENO}${FUNCNAME[0]:+:${FUNCNAME[0]}()}: '
          set -x
        fi
        shift 2
        ;;
      --dump)        
        KAMBRIUM_SHELL_DUMP=("${2:?"missing argument to $1"}")
        shift 2
        ;;
      --)   # Special argument to break argument parsing
        shift
        break
        ;;  
      -*) 
        echo "$SELFNAME: unknown option: $1" >&2
        exit 255 
        ;;
      *)    # Not an argument anymore
        break
        ;;  
    esac
  done
  [[ "$#" -gt 1 ]] && echo "$SELFNAME: too many arguments given" >&2 && exit 255
  
  local script_body="${1:-}"

  # if script_body is empty or only composed of empty lines or comments,
  # then do not process to avoid running (most of the time, involuntarily)
  # code with potential side-effects in the preload scripts or in the
  # prologues.
  local script_body_line='' script_body_has_code=no
  while read -r script_body_line; do
    if ! [[ "$script_body_line" =~ ^[" "\t]*($|\#) ]]; then
      script_body_has_code=yes
      break
    fi
  done <<< "$script_body"
    
  # optimization : abort execution if script consits only of comments
  [[ "$script_body_has_code" != yes ]] && exit 0

  # fix and export SHELL as it is explicitly changed and undefined by the
  # "bash-wrapper.mk" file. BASH should always be set and valid anyway
  export SHELL="${BASH:-/bin/sh}"  

  # we can now compose the script to be fed to a new bash instance that will
  # replace this current bash instance (see below)
  local script_lines
  script_lines=( '#!/usr/bin/env bash' 'set -e -u -o pipefail' '')

  # Note: MAKELEVEL appears to be the only variable always exported
  # within the recipe scripts whatever the ".EXPORT_ALL_VARIABLES" or
  # "unexport" settings.  We use this side-effect to assert if we are
  # currently running a recipe or not (i.e. a command executed within a
  # `$(shell ...)` make function).  In such case, also preload scripts
  # and unroll prologue meant for the recipes
  if [[ "${MAKELEVEL:-}" != '' ]]; then
    script_lines+=( "# this is a recipe. (MAKELEVEL=${MAKELEVEL:-<undefined>})" '')
    preloads=( "${always_preloads[@]}" "${preloads[@]}" )
    prologues=( "${always_prologues[@]}" "${prologues[@]}" )
  else
    script_lines+=( '# this is not a recipe. (MAKELEVEL is unset or empty)' '# Only loading unconditional preload(s) and prologue(s).' '')
    preloads=( "${always_preloads[@]}" )
    prologues=( "${always_prologues[@]}" )
  fi

  # include/source preloads
  (( "${#preloads[@]}" > 0 )) && script_lines+=( "# preload scripts:" "$(printf 'source %q\n' "${preloads[@]}")" '' )  

  # include/source prologues
  (( "${#prologues[@]}" > 0 )) && script_lines+=( "# prologue scripts:" "$(printf 'source %q\n' "${prologues[@]}")" '' )

  # append rest of the script (i.e. the Makefile recipe contents)
  # make doesnt strip the leading space per line since it does not know
  # our SHELL so we do it ourself using bash string subtitution
  # (this is needed to prevent heredoc warnings)
  script_lines+=( "${script_body//$'\n' /$'\n'}" )
  
  if [[ "${KAMBRIUM_SHELL_DUMP:-}" == 'true' ]]; then
    printf '%s\n' "${script_lines[@]}"
  else
    unset_KAMBRIUM_SHELL_vars_from_environment
    exec "${BASH:-bash}" <(printf '%s\n' "${script_lines[@]}")
  fi
}

unset_KAMBRIUM_SHELL_vars_from_environment() {
  for var in $(compgen -A export KAMBRIUM_SHELL_ || :); do
    [[ "$var" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ && -n "${!var+set}" ]] && unset "$var"
  done
}

main "$@"
