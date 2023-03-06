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
# 
# see [git.core documentation](https://github.com/git/git/blob/master/Documentation/config/core.txt)
# EOF
# 
.PHONY: init
init:
> KAMBRIUM_CORE_PATH=$$(realpath --relative-to=$$(pwd) node_modules/@pnpmkambrium/core)
> # configure git to use our git hooks
> git config core.hookspath "$${KAMBRIUM_CORE_PATH}/presets/default/.githooks"
> 
> # configure git to use true symlinks
> git config core.symlinks true
> 
> # configure our gitignore list ($${KAMBRIUM_CORE_PATH}/presets/default/.gitignore) via git config 
> # (best solution so far compared to linking to .gitignore or .git/info/exclude)
> git config core.excludesFile "$${KAMBRIUM_CORE_PATH}/presets/default/.gitignore"
# > {
# >   GIT_EXCLUDE_TEMPLATE="$${KAMBRIUM_CORE_PATH}/presets/default/.gitignore"
# >   GIT_EXCLUDE=.git/info/exclude
# >   if [[ ! -L $$GIT_EXCLUDE ]] || ! cmp -s -- $$GIT_EXCLUDE $$GIT_EXCLUDE_TEMPLATE; then
# >     # if (GIT_EXCLUDE not exists or not is a symlink (-L) or not points exact same content as GIT_EXCLUDE_TEMPLATE)
# >     # create a symlink GIT_EXCLUDE pointing to GIT_EXCLUDE_TEMPLATE
# >     #  (note that we use ln -r to automatically convert the target path to ../../$$GIT_EXCLUDE_TEMPLATE)
# >     # the ln -f option will force overwriting GIT_EXCLUDE even if its a existing file/link
# >     printf "[done] link local git exclude file to kambrium git exclude list : $$(ln -s -r -f -v $$GIT_EXCLUDE_TEMPLATE $$GIT_EXCLUDE)\n"
# >   fi
# > }
> 
> # tell git to treat all text files "to have `LF` line endings
> # instead of a .gitattributes file we can simply set git config option pointing to our git attribution 
> # (see details here : https://github.com/git/git/blob/master/Documentation/config/core.txt)
> git config core.attributesFile "$${KAMBRIUM_CORE_PATH}/presets/default/.gitattributes"

# HELP<<EOF
# Checks pnpmkambrium status  
#
# Tests if all settings, files and directories are properly set up 
# 
#  example: `make doctor` 
# EOF
.PHONY: doctor
doctor:
> KAMBRIUM_CORE_PATH=$$(realpath --relative-to=$$(pwd) node_modules/@pnpmkambrium/core)
> {
>   EXPECTED="$${KAMBRIUM_CORE_PATH}/presets/default/.githooks"
>   CURRENT="$$(git config core.hookspath)"
>   printf "[%1s] git config core.hookspath      (='%s')\n" "$$([[ "$$CURRENT" == "$$EXPECTED" ]] && printf '✔' || printf ' ')" "$$CURRENT" 
>   [[ "$$CURRENT" == "$$EXPECTED" ]] || printf "\t=> should be '$$EXPECTED'\n"
> }
> {
>   EXPECTED='true'
>   CURRENT="$$(git config core.symlinks)"
>   printf "[%1s] git config core.symlinks       (=%s)\n" "$$([[ "$$CURRENT" == "$$EXPECTED" ]] && printf '✔' || printf ' ')" "$$CURRENT" 
>   [[ "$$CURRENT" == "$$EXPECTED" ]] || printf "\t=> should be '$$EXPECTED'\n"
> }
> {
>   EXPECTED="$${KAMBRIUM_CORE_PATH}/presets/default/.gitignore"
>   CURRENT="$$(git config core.excludesFile)"
>   printf "[%1s] git config core.excludesFile   (='%s')\n" "$$([[ "$$CURRENT" == "$$EXPECTED" ]] && printf '✔' || printf ' ')" "$$CURRENT" 
>   [[ "$$CURRENT" == "$$EXPECTED" ]] || printf "\t=> should be '$$EXPECTED'\n"
> }
> {
>   EXPECTED="$${KAMBRIUM_CORE_PATH}/presets/default/.gitattributes"
>   CURRENT="$$(git config core.attributesFile)"
>   printf "[%1s] git config core.attributesFile (='%s')\n" "$$([[ "$$CURRENT" == "$$EXPECTED" ]] && printf '✔' || printf ' ')" "$$CURRENT" 
>   [[ "$$CURRENT" == "$$EXPECTED" ]] || printf "\t=> should be '$$EXPECTED'\n"
> }
> $(PNPM) -s doctor