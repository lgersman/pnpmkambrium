---
'@pnpmkambrium/pnpm-gitlog-per-package': patch
---

add pnpm git log tooling using a docker image

- development:

  - execute script locally using `./packages/docker/pnpm-gitlog-per-package/bin/pnpm-gitlog-per-package.sh`

  - `git log` command can be customized using environment variable `GIT_LOG_OPTIONS`.

    Examples:

    ```
    GIT_LOG_OPTIONS="--stat --abbrev-commit" ./packages/docker/pnpm-gitlog-per-package/bin/pnpm-gitlog-per-package.sh

    # see https://stackoverflow.com/questions/12082981/get-all-git-commits-since-last-tag
    # (note that git describe will fail if tag was not found)

    `GIT_LOG_OPTIONS="git log 1.2.0..$(git describe --tags --abbrev=0)" ./packages/docker/pnpm-gitlog-per-package/bin/pnpm-gitlog-per-package.sh`

    `GIT_LOG_OPTIONS="git log $(git describe --tags --abbrev=0 @^)..@" ./packages/docker/pnpm-gitlog-per-package/bin/pnpm-gitlog-per-package.sh`

    ```

  - build docker image : `pnpm kambrium-make packages/docker/pnpm-gitlog-per-package/`

    - build using the docker-compose file : `docker compose -f packages/docker/pnpm-gitlog-per-package/docker-compose.yml build`

      - run `docker compose -f packages/docker/pnpm-gitlog-per-package/docker-compose.yml run --rm pnpm-gitlog-per-package`

  - run docker image :

    ```
    docker run -it --rm -v $(pwd):/app pnpmkambrium/pnpm-gitlog-per-package

    # run with customized git log format
    docker run -it --rm -e GIT_LOG_OPTIONS="--stat --abbrev-commit"  -v $(pwd):/app pnpmkambrium/pnpm-gitlog-per-package
    ```

    run using a docker-compose file :

    - create docker-compose file :

    ```
    version: '3.3'
    services:
      main:
        image: pnpmkambrium/pnpm-gitlog-per-package:latest
        stdin_open: true
        tty:true
        # optional : customize git log options
        #    environment:
        #      GIT_LOG_OPTIONS: "--stat --abbrev-commit"
        volumes:
          - type: bind
            source: ${PWD}
            target: /app
    ```

    - execute : `docker compose -f pnpm-gitlog-per-package.yml run --rm main`

    - execute with customized `git log` output : `docker compose -f pnpm-gitlog-per-package.yml run --rm -e GIT_LOG_OPTIONS="--stat --abbrev-commit" main`
