# help related targets 

KAMBRIUM_SHELL_ALWAYS_PRELOAD += $(KAMBRIUM_MAKEFILE_DIR)/make-help.sh

# HELP<<EOF
#  prints the help screen
#
# by default the help will be rendered for the terminal using a few ansi escape sequences for highlighting
#
# to process the help information in other tools you can use the `FORMAT` variable to output help in JSON format.
#
# supported variables are : 
#   - `VERBOSE` (optional, default=``) enables verbose help parsing informations 
#   - `FORMAT` (optional, default=`text`) the output format of the help information
#      - `text` will print help in text format to terminal
#        - addional option `PAGER=false` may be used to output help without pagination
#     - `json` will print help in json format for further processing
#      - `markdown` will print help in markdown format for integrating output in static documentation
#
# environment variables can be provided using:
#   - make variables provided at commandline
#   - `.env` file from sub package
#   - `.env` file from monorepo root
#   - environment
# EOF
.PHONY: help 
help:
> @
> help=$$( VERBOSE=$${VERBOSE:-}; FORMAT=$${FORMAT:-}; kambrium:help < <(cat $(MAKEFILE_LIST)) )
> if [[ "$${FORMAT:-}" == '' ]]; then
>   if [[ "$${PAGER:-}" != 'false' ]]; then
>     echo -e "$$help" | less -r
>   else 
>     echo -e "$$help" 
>   fi
> elif [[ "$${FORMAT:-}" == 'json' ]]; then 
>   echo $$help | jq .
> elif [[ "$${FORMAT:-}" == 'markdown' ]]; then
>   echo "$$help"
> else 
>    echo "unknown FORMAT option(='$$FORMAT')" >&2 && false
> fi

# HELP<<EOF
# opens a interactive help menu utilizing fzf (https://github.com/junegunn/fzf)
#
# environment variables can be provided using:
#   - make variables provided at commandline
#   - `.env` file from sub package
#   - `.env` file from monorepo root
#   - environment
# EOF
.PHONY: interactive
interactive:
> @ 
> help=$$( VERBOSE=$${VERBOSE:-}; FORMAT=$${FORMAT:-json}; kambrium:help < <(cat $(MAKEFILE_LIST)) )
> HELP_FILE="$$(mktemp)"
> echo "$$help" > $$HELP_FILE
> # execute shaunch if exists locally. otherwise fallback to prepackaged shaunch docker image 
> if command -v ./packages/docker/shaunch/bin/shaunch.sh >/dev/null; then  
>   ./packages/docker/shaunch/bin/shaunch.sh --border-label " Make " --preview-label " Info " --title "Targets" -c "$$HELP_FILE" ||:
> else
>   docker run -it --rm -v $$(dirname $$HELP_FILE):/app pnpmkambrium/shaunch --border-label " Make " --preview-label " Info " --title "Targets" -c "/app/$$(basename $$HELP_FILE)" ||:
> fi
> trap "rm -f -- $$HELP_FILE" EXIT


