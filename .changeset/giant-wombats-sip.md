---
'@pnpm-kambrium/pnpm-gitlog-per-package': patch
---

add pnpm git log tooling using a docker image

- development:

  - execute script using `./packages/docker/pnpm-gitlog-per-package/bin/pnpm-gitlog-per-package.sh`

  - ` git log``command can be customized using environment variable  `GIT_LOG_OPTIONS`.

    Examples:

    ```
    GIT_LOG_OPTIONS="--stat --abbrev-commit" ./packages/docker/pnpm-gitlog-per-package/bin/pnpm-gitlog-per-package.sh

    # see https://stackoverflow.com/questions/12082981/get-all-git-commits-since-last-tag
    # (note that git describe will fail if tag was not found)

    - `GIT_LOG_OPTIONS="git log 1.2.0..$(git describe --tags --abbrev=0)" ./packages/docker/pnpm-gitlog-per-package/bin/pnpm-gitlog-per-package.sh`

    - `GIT_LOG_OPTIONS="git log $(git describe --tags --abbrev=0 @^)..@" ./packages/docker/pnpm-gitlog-per-package/bin/pnpm-gitlog-per-package.sh`

    ```

  -
