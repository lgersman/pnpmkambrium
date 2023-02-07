# contains the make help target

#
# <<EOD
# hihi
# 	huhu
# haha
# EOD
#
.PHONY: bar
bar:

#
# <<EMPTY_:-.HELP
# EMPTY_:-.HELP
#

#
# <<EOF
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
# <<HELP
# xxx
# 	yyy
# zzz
# HEL
#
.PHONY: xxxx
xxxx:

#
# <<DDD
# mi
# 	ka
# do
# DDD
#
.PHONY: yyyy
yyyy:

