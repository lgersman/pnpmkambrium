# contains generic make functions 

# function for testing the existence of a list of commands
#
# example usage : 
# mytarget: 
# # ensure commands  ls, dd, dudu and lxop exists
# > $(call ensure-commands-exists, ls dd dudu lxop)
#
# see see https://www.gnu.org/software/make/manual/make.html#Call-Function and https://www.gnu.org/software/make/manual/make.html#Canned-Recipes
ensure-commands-exists = $(foreach command,$1,\
  $(if $(shell command -v $(command)),some string,$(error "Could not find executable '$(command)' - please install '$(command)'")))

# function for testing the existence of a list of docker images
#
# example usage : 
# mytarget: 
# > # ensure images  foo/bar, fedora:latest exists
# > $(call ensure-docker-images-exists, foo/bar fedora:latest)
#
define ensure-docker-images-exists
	$(foreach image,$1,
		if ! docker image inspect '$(image)' >/dev/null 2>&1; then
			if ! pnpm --filter='@$(image)' pwd | grep 'No projects' >/dev/null; then
				make_target="$$(realpath --relative-to=$(CURDIR) $$(pnpm --filter="@$(image)" exec pwd))/"
				echo "Image '@$(image)' not available : It's available as monorepo sub package(path='$$make_target') - build it and try again." >&2
				exit -1
			else 
				docker pull "$(image)" >/dev/null 2>&1 || echo "Image '@$(image)' not available : could not download image from docker hub" >&2
				exit -1
			fi
		fi
	) 
endef

#
#	dump make variables 
# example usage : 
# mytarget: 
# > $(call kambrium_dump_vars)
#
define kambrium_dump_vars
	# see https://www.cmcrossroads.com/article/dumping-every-makefile-variable
	$(foreach \
		V, \
		$(filter-out \
			TERMINAL_GREY TERMINAL_YELLOW TERMINAL_RESET SHELL _ ensure-commands-exists ensure-docker-images-existsdump_vars, \
			$(sort $(.VARIABLES)), \
		), \
		$(if \
			$(filter-out \
				environment% default undefined, \
				$(origin $V)\
			), \
			$(info $(TERMINAL_GREY)$V=$($V)$(TERMINAL_RESET) ($(value $V))) \
		) \
	)
endef