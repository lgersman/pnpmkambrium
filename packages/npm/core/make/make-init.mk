#
# HELP<<EOF
# initialize a pnpmkambrium workspace and (re)create required files / settings for a pnpmkambrium workspace  
#
# this target is automagically called when the @pnpmkambrium/core package gets installed by node package manager. 
# 
# you can call it even manually to force (re)creation of all files/settings required by pnpmkambrium
#
# environment variables can be provided using:
#   - make variables provided at commandline
#   - `.env` file from monorepo root
#   - environment
#
#  example: `make init` 
#
# EOF
# 
.PHONY: init
init: 
> 	set -x
> # initialize our gitignore list in .git/info/excludes 
> # see https://stackoverflow.com/a/45018435/1554103 
> GIT_EXCLUDE_TEMPLATE=$$(realpath --relative-to=$$(pwd) node_modules/@pnpmkambrium/core/presets/default/.gitignore)
> GIT_EXCLUDE=.git/info/exclude
> if [[ -L $$GIT_EXCLUDE ]] && diff $$GIT_EXCLUDE $$GIT_EXCLUDE_TEMPLATE; then
> 	# if GIT_EXCLUDE exists and is a symlink (-L) and points exact same content as GIT_EXCLUDE_TEMPLATE
>   echo "[skip] $$GIT_EXCLUDE links to $$GIT_EXCLUDE_TEMPLATE"
> else
> 	rm -f $$GIT_EXCLUDE
> 	# create a symlink GIT_EXCLUDE pointing to GIT_EXCLUDE_TEMPLATE
> 	printf "[done] create local git ignore file : $$(ln -s $$GIT_EXCLUDE_TEMPLATE $$GIT_EXCLUDE)\n"
> fi