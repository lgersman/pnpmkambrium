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
> KAMBRIUM_CORE_PATH=$$(realpath --relative-to=$$(pwd) node_modules/@pnpmkambrium/core)
> # configure git to use our git hooks
> git config core.hookspath "$${KAMBRIUM_CORE_PATH}/presets/default/.githooks"
> 
> # configure git to use true symlinks (https://github.com/git/git/blob/master/Documentation/config/core.txt)
> git config core.symlinks true
> 
> # initialize our gitignore list in .git/info/excludes 
> # see https://stackoverflow.com/a/45018435/1554103 
> GIT_EXCLUDE_TEMPLATE="$${KAMBRIUM_CORE_PATH}/presets/default/.gitignore"
> GIT_EXCLUDE=.git/info/exclude
> if [[ ! -L $$GIT_EXCLUDE ]] || ! cmp -s -- $$GIT_EXCLUDE $$GIT_EXCLUDE_TEMPLATE; then
>   # if (GIT_EXCLUDE not exists or not is a symlink (-L) or not points exact same content as GIT_EXCLUDE_TEMPLATE)
>   # create a symlink GIT_EXCLUDE pointing to GIT_EXCLUDE_TEMPLATE
>   # (note that we use ln -r to automatically convert the target path to ../../$$GIT_EXCLUDE_TEMPLATE)
>   # the ln -f option will force overwriting GIT_EXCLUDE even if its a existing file/link
>   printf "[done] link local git exclude file to kambrium git exclude list : $$(ln -s -r -f -v $$GIT_EXCLUDE_TEMPLATE $$GIT_EXCLUDE)\n"
> fi