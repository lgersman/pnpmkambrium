# contains generic make targets executed across sub packages 

#HELP: build all outdated packages of any flavor
packages/: $$(wildcard $$(@D)/*/) ;

.PHONY: build
#HELP: convenient alias for target "packages/"
build: packages/