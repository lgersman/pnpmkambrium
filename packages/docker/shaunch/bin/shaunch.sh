#!/usr/bin/env bash

# Desc: shows a list of commands and their markdown rendered documentation
#
# Usage: execute shaunch.sh in the root of a monorepo 
#
# script supports customization using @TODO: 
# Example: 
# @TODO:
#
# Requires: wget, jq, bat/batcat (will be installed if not present), fzf >= 0.29.0 (will be installed if not present)
#
# Author: Lars Gersmann<lars.gersmann@cm4all.com>
# Created: 2022-12-02
# License: See repository LICENSE file.

set -Eeuo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

# download latest fzf 
if ! (command -v "$script_dir/fzf" 1 > /dev/null); then
  (cd "$script_dir/.." && wget -qO- https://raw.githubusercontent.com/junegunn/fzf/master/install | $SHELL -s -- --bin)
fi

# download latest bat/batcat
if ! (command -v "$script_dir/bat" 1 > /dev/null); then
  curl -s https://api.github.com/repos/sharkdp/bat/releases/latest | \
    grep "browser_download_url.*-i686-unknown-linux-musl.tar.gz" | \
    cut -d : -f 2,3 | \
    tr -d \" | \
    wget -i - -qO - | \
    tar -zxvf - --strip-components=1 -C $script_dir --wildcards */bat 
fi

help() {
  cat << EOF # remove the space between << and EOF, this is due to web plugin issue
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-f] -p param_value arg1 [arg2...]

Script description here.

Available options:

-h, --help                      Print this help and exit
-v, --verbose                   Print script debug info
-f, --flag                      Some flag description
-t, --title                     Title string above the commands to launch
-c, --commands <dir/executable> Directory to scan for commands (defaults to current directory) 
                                or executable returning commands 
EOF
  exit
}

function _scan_commands() {
  local dir=$(realpath --relative-to=$(pwd) $1)
  local json='[]'

  for script in $(find "$dir" -maxdepth 1 -type f -executable -printf '%f\n' | sort); do
    json=$(\
      echo "$json" | 
      jq \
        --arg caption "$script" \
        --arg help "${dir}/${script}.md" \
        --arg exec "${dir}/${script}" \
        '. += [ { "caption" : $caption, "help" : $help, "exec" : $exec } ]' \
      )
  done

  echo $json | jq .
}

parse_params() {
  while :; do
    case "${1-}" in
      -h | --help)
        help
      ;;
      -v | --verbose) 
        set -x 
      ;;
      -t | --title) 
        TITLE="${2-}"
        shift
      ;;
      -c | --commands) 
        if [[ -d "${2-}" ]]; then
          export COMMANDS=$(_scan_commands "${2-}")
        elif [[ -x "${2-}" ]]; then
          export COMMANDS=$("${2-}")
        else 
          >&2 echo "given option commands(=${2-}) expected to be a directory or executable"
          exit -1;
        fi
        shift
      ;;
      -?*) 
        die "Unknown option: $1" 
      ;;
      *) 
        break 
      ;;
    esac
    shift
  done

  args=("$@")

  TITLE=${TITLE:-Commands}
}

# export original command to make it available to calling scripts
export SHAUNCH_COMMAND="${BASH_SOURCE[0]} $@"

parse_params "$@"

# echo $COMMANDS | jq -r '.[] | select(.caption=="unmount").help'
CAPTIONS=$(echo $COMMANDS | jq -r '.[] | select(.caption) | .caption')

PREVIEW_CMD="$script_dir/bat --paging=always --style=plain --color=always  \$(echo '$COMMANDS' | jq -r '.[] | select(.caption==\"{}\").help')"
# --bind 'esc:execute(echo "$1" && exit)' \
cmd=$("$script_dir/fzf" \
  --reverse \
  --no-sort \
  --select-1 \
  --no-multi \
  --border=rounded \
  --no-info \
  --exit-0 \
  --prompt='filter: ' \
  --header-lines=3 \
  --ansi \
  --preview-window=80% \
  --preview="$PREVIEW_CMD" \
  < <(echo "
$TITLE

${CAPTIONS}")
)  

bash -c "$(echo $COMMANDS | jq -r ".[] | select(.caption==\"$cmd\").exec")"
