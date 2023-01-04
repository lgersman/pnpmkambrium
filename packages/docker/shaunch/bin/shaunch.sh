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
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") -c <dir/executable> [options...]

A terminal ui exposing commands and their markdown documentaion 

Available options:

-h,  --help                      Print this help and exit
-v,  --verbose                   Print script debug info
-f,  --flag                      Some flag description
-pl, --preview-label             preview/documentation label text
-bl, --border-label              shaunch label text
-t,  --title                     Title string above the commands to launch
-c,  --commands <dir/executable> Directory to scan for commands (defaults to current directory) 
                                 or executable returning commands 
EOF
  exit
}

# built-in fallback function scanning a directory for exeutables and matching md file
function scan_commands() {
  local dir=$(realpath --relative-to=$(pwd) $1)
  local json='[]'

  for script in $(find "$dir" -maxdepth 1 -type f -executable -printf '%f\n' | sort); do
    # append script only if matching markdown file exists
    if [[ -f "${dir}/${script}.md" ]]; then
      json=$(\
        echo "$json" | 
        jq \
          --arg caption "$script" \
          --arg help "${dir}/${script}.md" \
          --arg exec "${dir}/${script}" \
          '. += [ { "caption" : $caption, "help" : $help, "exec" : $exec } ]' \
        )
    fi
  done

  echo $json | jq .
}

# executed on preview by markdown
function render_markdown() {
  local help=$(echo "$COMMANDS" | jq --arg caption "$1" -r '.[] | select(.caption==$caption).help')

  if (command -v "$help" 1 > /dev/null); then
    # if markdown file is a executable : execute it and interpret its output as markdown
    $help | $script_dir/bat --language=md --paging=always --style=plain --color=always -
  elif [[ -f "$help" ]]; then
    # if its a regular markdown file 
    $script_dir/bat --paging=always --style=plain --color=always "$help"
  else
    # otherwise interpret content as markdown content
    echo "$help" | $script_dir/bat --language=md --paging=always --style=plain --color=always -
  fi
}

# executed on enter key from fzf
function execute() {
  local command_caption="$1"

  local exec=$(echo "$COMMANDS" | jq --arg caption "$command_caption" -r '.[] | select(.caption==$caption).exec')
  bash -c "$exec"
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  echo "$msg" >&2
  exit "$code"
}

# exported command to make it available to calling scripts
function shaunch:() {
  while :; do
    case "${1-}" in
      exit)
        # kill fzf
        kill "$_shaunch_pid" 
        break;
      ;;
      *) 
        echo "Unknown shaunch command: $1" 
        break 
      ;;
    esac
    shift
  done
}

export -f shaunch:

# parse commandline parameters
parse_params() {
  while :; do
    case "${1-}" in
      render_markdown)
        shift
        render_markdown "$@"
        exit
      ;;
      execute)
        shift
        execute "$@"
        exit
      ;;
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
      -pl | --preview-label) 
        PREVIEW_LABEL="${2-}"
        shift
      ;;
      -bl | --border-label) 
        BORDER_LABEL="${2-}"
        shift
      ;;
      -c | --commands) 
        if [[ -d "${2-}" ]]; then
          export COMMANDS=$(scan_commands "${2-}")
        elif [[ -x "${2-}" ]]; then
          export COMMANDS=$("${2-}")
        else 
          die "given option commands(=${2-}) expected to be a directory or executable"
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
  BORDER_LABEL=${BORDER_LABEL:-  Shaunch  }
  PREVIEW_LABEL=${PREVIEW_LABEL:-  Documentation  }
}

if [[ $# == 0 ]]; then
  help
fi

parse_params "$@"

PREVIEW_CMD="'${BASH_SOURCE[0]}' render_markdown '{}'"
# --bind 'esc:execute(echo "$1" && exit)' \
# see https://github.com/junegunn/fzf/issues/3089#issuecomment-1353158088 for the $PPID thingie
cmd=$("$script_dir/fzf" \
  --reverse \
  --border-label "$BORDER_LABEL" \
  --preview-label "$PREVIEW_LABEL" \
  --no-sort \
  --select-1 \
  --no-multi \
  --border=rounded \
  --no-info \
  --exit-0 \
  --bind "Enter:execute(export _shaunch_pid=\$PPID; '${BASH_SOURCE[0]}' execute '{}' >/dev/tty)" \
  --prompt='filter: ' \
  --header-lines=3 \
  --ansi \
  --preview-window=80% \
  --preview="$PREVIEW_CMD" \
  < <(echo "
$TITLE

$(echo $COMMANDS | jq -r '.[] | select(.caption) | .caption')")
)

# bash -c "$(echo $COMMANDS | jq -r ".[] | select(.caption==\"$cmd\").exec")"
