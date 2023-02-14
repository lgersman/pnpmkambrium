# contains generic make targets executed across sub packages 

# HELP<<EOF
# convenience alias for target `packages/`
# EOF
.PHONY: build
build: packages/

# HELP<<EOF
# build all outdated sub packages of any flavor
# EOF
packages/: $$(wildcard $$(@D)/*/) ;