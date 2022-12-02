# about

@TODO: add link to docker demo gif

# usage

```
docker run -it --rm -v $(pwd):/app pnpmkambrium/shaunch
```

- run using a docker-compose file :

  - create docker-compose file :

  ```
  version: '3.3'
  services:
    main:
      image: pnpmkambrium/shaunch:latest
      stdin_open: true
      tty:true
      volumes:
        - type: bind
          source: ${PWD}
          target: /app
  ```

  execute : `docker compose -f shaunch.yml run --rm main`

- execute with customized `git log` output : `docker compose -f shaunch.yml run --rm -e GIT_LOG_OPTIONS="--stat --abbrev-commit" main`

# development

- execute script locally using `./packages/docker/shaunch/bin/shaunch.sh`

- build docker image : `pnpm kambrium-make packages/docker/shaunch/`

- build using the docker-compose file : `docker compose -f packages/docker/shaunch/docker-compose.yml build`

- run `docker compose -f packages/docker/shaunch/docker-compose.yml run --rm shaunch`
