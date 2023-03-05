# contains generic make targets executed across sub packages 

# HELP<<EOF
# convenience alias for target `packages/`
#  
# EOF
.PHONY: build
build: packages/

# HELP<<EOF
# build all outdated sub packages of any flavor
# EOF
packages/: $$(wildcard $$(@D)/*/) ;

# enable template support for *.kambrium-template files
% : %.kambrium-template $(ENV_FILES)
> # import matching .env file if template is located in a monorepo package directory  
> if [[ "$<" =~ ^(packages/([^/]+/){2}) ]]; then
>   # set -a causes variables defined from now on to be automatically exported.
>   set -a
>   DOT_ENV="$${BASH_REMATCH[1]}.env"; [[ -f $$DOT_ENV ]] && source $$DOT_ENV 
> fi
> command -v "$<" 1 > /dev/null && 
>   echo "$< => $@" && 
>   "$<" > "$@" ||
>   (echo "template(=$<) is no executable : don't know how to generate target file(=$@)" >&2 && false)