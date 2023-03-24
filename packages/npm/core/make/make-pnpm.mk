# contains pnpm/node related make targets/definitions

# ensure pnpm is available
ifeq (,$(shell command -v pnpm))
  define PNPM_NOT_FOUND
pnpm is not installed or not in PATH. 
Install it using "wget -qO- 'https://get.pnpm.io/install.sh' | sh -"
(windows : 'iwr https://get.pnpm.io/install.ps1 -useb | iex') 

See more here : https://docs.npmjs.com/getting-started/installing-node 
  endef
  $(error $(PNPM_NOT_FOUND))
else
  PNPM != command -v pnpm
endif

# ensure a recent nodejs version is available
# (required by pnpm)
ifeq (,$(shell command -v node))
  define NODEJS_NOT_FOUND
node is not installed or not in PATH. 
See more here : https://nodejs.org/en/download/ 
  endef
  $(error $(NODEJS_NOT_FOUND))
endif

# pnpm env use --global $(grep -oP '(?<=use-node-version=).*' ./.npmrc1)
# node version to use by pnpm (defined in .npmrc)
NODE_VERSION != sed -n '/^use-node-version=/ {s///p;q;}' .npmrc

# path to node binary configured in .npmrc
NODE := $(HOME)/.local/share/pnpm/nodejs/$(NODE_VERSION)/bin/node

# this target triggers pnpm to download/install the required nodejs if not yet available 
$(NODE):
# > @$(PNPM) exec node --version 1&>/dev/null
# > touch -m $@

pnpm-lock.yaml: package.json 
>  $(PNPM) install --lockfile-only
> @touch -m pnpm-lock.yaml

node_modules/: pnpm-lock.yaml 
# pnpm bug: "pnpm use env ..." is actually not needed but postinall npx calls fails
> $(PNPM) env use --global $(NODE_VERSION)
>  $(PNPM) install --frozen-lockfile
> @touch -m node_modules