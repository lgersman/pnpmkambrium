# contains pnpm/node related make targets/definitions

# this target triggers pnpm to download/install the required nodejs if not yet available
$(NODE):
# > @$(PNPM) exec node --version 1&>/dev/null
# > touch -m $@

pnpm-lock.yaml: package.json
> $(PNPM) install --lockfile-only
> touch -m pnpm-lock.yaml

node_modules/: pnpm-lock.yaml
# pnpm bug: "pnpm use env ..." is actually not needed but postinall npx calls fails
> $(PNPM) env use --global $(NODE_VERSION)
> $(PNPM) install --frozen-lockfile
> touch -m node_modules
