# contains the make help target

#
# HELP<<EOD
# hihi
# 	huhu
# haha
# EOD
#
.PHONY: bar
bar:

#
# HELP<<EMPTY_:-.HELP
# EMPTY_:-.HELP
#

#
# HELP<<EOF
# whats up ?
# here we <i>go
# EOF
#
.PHONY: foo
foo:
> # import kambrium bash function library
> . "$(KAMBRIUM_MAKEFILE_DIR)/make-bash-functions.sh"
> help=$$( VERBOSE=$${VERBOSE:-}; FORMAT=$${FORMAT:-text}; kambrium:help < <(cat $(MAKEFILE_LIST)) )
> echo -e "$$help"

#
# HELP<<HELP
# xxx
# 	yyy
# zzz
# HEL
#
.PHONY: xxxx
xxxx:

# HELP<<EOF
# build all outdated dockern images in general packages/docker/
# EOF
.PHONY: uuu
uuu:

#
# HELP<<DDD
# mi
# 	ka
# do
# DDD
#
.PHONY: yy-%yy
yy-%yy:

