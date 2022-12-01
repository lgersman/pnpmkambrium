---
'@pnpmkambrium/pnpm-gitlog-per-package': patch
'@pnpmkambrium/core': patch
'@pnpmkambrium/create': patch
---

- add git hooks / commitizen support using NPM script/hook `prepare` in your monorepo root package.json :

  ```
  ...
  "scripts": {
    "prepare": "npx -y only-allow pnpm && git config core.hookspath packages/npm/core/presets/default/.githooks",
    "make": "make --include-dir ./packages/npm/core/bin/ -f ./packages/npm/core/bin/kambrium-make.mk --"
  }
  ...
  ```

- the following git hooks will be installed :

  - hook `pre-commit` will execute `nano-staged` to verify commitizen standard conformance of staged sources

  - hook `prepare-commit-message` will utilize `git cz` to compute the git commit message interactively

  - hook `commit-msg` will execute `commitlint` to verify commitizen standard conformance

- the git hooks will be triggered by GIT when using `git commit`
