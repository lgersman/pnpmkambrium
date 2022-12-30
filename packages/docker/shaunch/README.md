[shaunch](https://github.com/lgersman/pnpmkambrium/tree/develop/packages/docker/shaunch) is a launcher for the terminal

It's based on [fzf](https://github.com/junegunn/fzf) and [batcat](https://github.com/sharkdp/bat)

@TODO: add link to docker demo gif

I wrote [shaunch](https://github.com/lgersman/pnpmkambrium/tree/develop/packages/docker/shaunch) because i needed a tool make terminal commands available in a user friendly manner.

# Features

- shows both the available commands and their documentation in the terminal

- commands can be started by just pressing `enter`

- command documentation supports [markdown](https://www.markdownguide.org/) rendered to the terminal

- documentation can be provided as static markdown files or even as executables outputting [markdown](https://www.markdownguide.org/). The latter enables you to display dynamic markdown files containing a status or whatever.

- can be used as :

  - pre-packaged docker image
  - [self contained bash script](https://github.com/lgersman/pnpmkambrium/blob/develop/packages/docker/shaunch/bin/shaunch.sh)
    - [fzf](https://github.com/junegunn/fzf) and [batcat](https://github.com/sharkdp/bat) will be downloaded/installed on demand to a [shaunch](https://github.com/lgersman/pnpmkambrium/tree/develop/packages/docker/shaunch) private directory

- when started with `-c <directory>` the contained scripts and documentation files will be out of the box presented to the user (see [static directory example](https://github.com/lgersman/pnpmkambrium/tree/develop/packages/docker/shaunch/examples/commands-by-directory))

- when started with `-c <executable>` the executable is executed and its output is consumed to gather the available scripts and documentation (see [dynamic script example](https://github.com/lgersman/pnpmkambrium/tree/develop/packages/docker/shaunch/examples/commands-by-script))

# Installation

## Local

@TODO:

# Configuration

@TODO: commandine arguments

## Show commands by reading directory

see [static directory example](https://github.com/lgersman/pnpmkambrium/tree/develop/packages/docker/shaunch/examples/commands-by-directory)

## Dynamic commands evaluation

@TODO: json schema for expected output

[dynamic script example](https://github.com/lgersman/pnpmkambrium/tree/develop/packages/docker/shaunch/examples/commands-by-script)

# Usage

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

# Development

- execute script locally

  - by browsing a directory : `./packages/docker/shaunch/bin/shaunch.sh -c ./packages/docker/shaunch/examples/commands-by-directory/`

  - by executing a script: `./packages/docker/shaunch/bin/shaunch.sh -c ./packages/docker/shaunch/examples/commands-by-script/commands-by-script`

- build docker image : `make packages/docker/shaunch/`

- build using the docker-compose file : `docker compose -f packages/docker/shaunch/docker-compose.yml build`

- run `docker compose -f packages/docker/shaunch/docker-compose.yml run --rm shaunch`

# Limitations

- The local bash script works right now only on x86 machines.

  @TODO: This can be easily fixed by downloading the correct [fzf](https://github.com/junegunn/fzf) and [batcat](https://github.com/sharkdp/bat) binaries depending on the platform.

# FAQ

- How can I exit `shaunch` from a command ?

  Just call `shaunch exit` in your command script (see [dynamic configuration example](https://github.com/lgersman/pnpmkambrium/tree/develop/packages/docker/shaunch/examples/commands-by-script)). The `shaunch` command is a exported function exporting some operations like exiting.
