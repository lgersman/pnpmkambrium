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

%: %.kambrium-template
> echo "transforming $< => $@"
> [[ -x "$<" ]] && "$<" > $@ || echo "template(=$<) is not executable : don't know how to generate target file(=$@)"

KAMBRIUM_TEMPLATES := $(shell find . -type f -name '*.kambrium-template')
KAMBRIUM_TEMPLATE_TARGETS := $(patsubst %.kambrium-template, %, $(TEMPLATES))
.PHONY: templates
templates: $(KAMBRIUM_TEMPLATE_TARGETS) ;