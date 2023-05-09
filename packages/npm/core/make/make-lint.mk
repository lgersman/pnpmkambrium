# lint related targets

# always run prettier using ignored files from .lintignore
PRETTIER := $(PNPM) prettier --ignore-path='$(CURDIR)/.lintignore' --cache --check

# always run eslint using ignored files from .lintignore
ESLINT := $(PNPM) eslint --ignore-path='$(CURDIR)/.lintignore' --no-error-on-unmatched-pattern

# HELP<<EOF
# lint sources
# EOF
.PHONY: lint
lint: node_modules/
> pnpm run -r --if-present lint
> $(PRETTIER) --ignore-unknown .
> $(ESLINT) .
> ! (command -v $$($(PNPM) bin)/stylelint >/dev/null) || \
>   $(PNPM) stylelint --ignore-path='$(CURDIR)/.lintignore' --allow-empty-input ./packages/**/*.{css,scss}
> {
>   echo "Checking for unwanted tabs in makefiles..."
>   ! git --no-pager grep --no-color --no-exclude-standard --untracked --no-recurse-submodules -n $$'\t' Makefile **/*.mk \
>     | sed -e "s/\t/\x1b\[31m'\\\\t\x1b\[0m/"
>   kambrium.log_done
> }

# HELP<<EOF
# lint the project and apply fixes provided by the linters
# EOF
.PHONY: lint-fix
lint-fix: node_modules/
> pnpm run -r --if-present lint-fix
> $(PRETTIER) --cache --check --write .
> $(ESLINT) --fix .
> ! (command -v $$($(PNPM) bin)/stylelint >/dev/null) || \
>   $(PNPM) stylelint --ignore-path='$(CURDIR)/.lintignore' --allow-empty-input --fix ./packages/**/*.{css,scss}
> # lint-fix make files (poor mans edition): replace tabs with 2 spaces
> (git --no-pager grep --no-color --no-exclude-standard --untracked --no-recurse-submodules -nH --name-only $$'\t' Makefile **/*.mk \
>   | xargs -I '{}' -r bash -c \
>   ' \
>     sed -i -e "s/\t/  /g" {}; \
>     printf "[done] fixed makefile(=%s) : replaced tabs with 2 spaces\n" {} \
>   ')||:
