#
# this file configures make SHELL / SHELLFLAGS to use our own bash wrapper
# to automagically preloading bash scripts/libraries available in make targets and make shell function calls  
#  
# see https://github.com/lgersman/make-auto-import-bash-library-using-shell-wrapper-demo/ for inspiration
#

# undefine any KAMBRIUM_SHELL_ variables that may be (unintended) inherited
# from the environment or the Make command line variables
override undefine KAMBRIUM_SHELL_PRELOAD
override undefine KAMBRIUM_SHELL_PROLOGUE
override undefine KAMBRIUM_SHELL_ALWAYS_PRELOADm
override undefine KAMBRIUM_SHELL_ALWAYS_PROLOGUE

# set to true in your Makefile to enable bash xtrace 
KAMBRIUM_SHELL_XTRACE ?= false

# set to true in your Makefile to dump the generated bash code instead of executing it 
KAMBRIUM_SHELL_DUMP ?= false

# it is important that the SHELL and .SHELLFLAGS variables must not be inherited from the environment.
#
# We cannot use SHELL=bash with the "make-shell.sh" script as argument to bash. 
# there is a special handling of the recipe lines parsing if the shell is detected to be a bash by gnu make
# (i.e. /bin/sh, /bin/ksh and so on).  in that scenario, leading `-`, `+` and `@` characters are trimmed within the recipe content. 
# this preprocessing may break some bash scripts that we want to inject into the wrapper script.
# let's stick with the path to "make-shell.sh" file marked as executable.
# 
# @see the GNU Make source code and read function
# `construct_command_argv_internal()` (see the few lines that follow the call
# to the function `is_bourne_compatible_shell` within it).
#
override SHELL := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))/make-shell.sh
# transform configured bash scripts to commandline options provided to our make-shell main() function later on
# note that this variable is lazy evaluated which in turn means 
# that it is evaluated again each time it gets accessed
override .SHELLFLAGS = $(foreach ._item,$(KAMBRIUM_SHELL_PRELOAD),--preload $(._item)) \
  $(foreach ._item,$(KAMBRIUM_SHELL_PROLOGUE),--prologue $(._item)) \
  $(foreach ._item,$(KAMBRIUM_SHELL_ALWAYS_PRELOAD),--always-preload $(._item)) \
  $(foreach ._item,$(KAMBRIUM_SHELL_ALWAYS_PROLOGUE),--always-prologue $(._item)) \
  --xtrace $(KAMBRIUM_SHELL_XTRACE) \
  --dump $(KAMBRIUM_SHELL_DUMP) \
  --

# explicitly do *NOT* export SHELL as it may break some scripts or third-party
# programs used in make recipes since at this current point, SHELL is the path
# to "make-shell.sh" (see above) which is not a real true shell.
unexport SHELL