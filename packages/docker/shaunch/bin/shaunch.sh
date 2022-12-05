#!/usr/bin/env bash

# Desc: shows a list of commands and their markdown rendered documentation
#
# Usage: execute shaunch.sh in the root of a monorepo 
#
# script supports customization using @TODO: 
# Example: 
# @TODO:
#
# Requires: wget, bat/batcat (will be installed if not present), fzf >= 0.29.0 (will be installed if not present)
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
-c, --commands-directory <dir>  Directory to scan for commands (defaults to current directory)
--suppress-exit-on-escape       if set $(basename ${BASH_SOURCE[0]}) cannot be exited using <Escape>
-e, --execute                   Executes selected command directly after pressing <Enter>
  -r --restart                  Restart $(basename ${BASH_SOURCE[0]}) after command was executed (only if execute option ist enabled) 
EOF
  exit
}

parse_params() {
  # default values of variables set from params
  flag=0
  param=''

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
      -c | --commands-directory) 
        COMMANDS_DIRECTORY="${2-}"
        shift
      ;;
      -e | --execute) 
        EXECUTE="y"
      ;;
      -r | --restart) 
        RESTART="y"
      ;;
      --suppress-exit-on-escape)
        SUPPRESS_EXIT_ON_ESCAPE=''
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
}

parse_params "$@"

TITLE=${TITLE:-Commands}
COMMANDS_DIRECTORY=${COMMANDS_DIRECTORY:-.}
EXECUTE=${EXECUTE:-n}
RESTART=${RESTART:-n}
SUPPRESS_EXIT_ON_ESCAPE=${SUPPRESS_EXIT_ON_ESCAPE:-}

PREVIEW_CMD="cd '$COMMANDS_DIRECTORY' && $script_dir/bat --paging=always --style=plain --color=always '{}.md'"
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
  --bind 'esc:execute(echo "$1" && exit)' \
  --preview-window=80% \
  --preview="$PREVIEW_CMD" \
  < <(echo "
$TITLE

$(find "$COMMANDS_DIRECTORY" -maxdepth 1 -type f -executable -printf '%f\n' | sort)")
)  

if [[ "$EXECUTE" == 'y' ]]; then
  echo "whoop"
else
  # @TODO: it would be nice to output the selected command to the terminal prompt AFTER the script exists
  # like fzf can do using _fzf_complete
  echo "./${cmd}"
fi