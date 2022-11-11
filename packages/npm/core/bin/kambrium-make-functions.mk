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
