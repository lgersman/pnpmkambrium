[shaunch](https://github.com/lgersman/pnpmkambrium/tree/develop/packages/docker/shaunch) is a launcher for the terminal

It's based on [fzf](https://github.com/junegunn/fzf) and bash/jq :-)

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

- when started with `-c <directory>` the contained scripts and documentation files will be out of the box presented to the user (see [static directory example](https://github.com/lgersman/pnpmkambrium/tree/develop/packages/docker/shaunch/examples/commands-by-directory)). Output will be assumed to be JSON according to the shaunch json schema definition

- when started with `-c <executable>` the executable is executed and its output is consumed to gather the available scripts and documentation (see [dynamic script example](https://github.com/lgersman/pnpmkambrium/tree/develop/packages/docker/shaunch/examples/commands-by-script)). Output will be assumed to be JSON according to the shaunch json schema definition.

- when started with a regular file the file will be assumed to be JSON according to the shaunch json schema definition

# Installation

Shaunch is available

- as self contained Bash script

- as preinstalled docker image `pnpmkambrium/shaunch` containing Shaunch and its dependencies

## Local

Shaunch can be executed locally by just executing the shaunch script. Any dependencies will be downloaded on demand.

# Configuration

The software can be configured using JSON.

The JSON format is described [here](./docs/shaunch.schema.json)

```json
{{#include ./docs/shaunch.schema.json}}
```

## Static configuration

Providing a file with the following contents using the `-c` option to `shaunch` will open up a terminal ui (utilizing `fzf`) showing all commands.

By selecting a command, its markdown help will be rendered in the terminal.

By htting `Enter` the `exec` and `prompt` parameters will be executed/displayed if given.

```json
[
  {
    // caption is what will be shown as command title
    "caption": "Mount",
    // help for this command will be evaluated by executing script ./docs/mount.md.sh
    // the script is expected to return markdown
    "help": "./docs/mount.md.sh",
    // the exec content will be executed within shaunch. after exiting the script the shaunch ui will appear again
    "exec": "echo 'mounted'\nPress any key to continue ...'; read  -n 1"
  },
  {
    "caption": "Status",
    // help for this command will be rendered from a markdown file
    "help": "./docs/status.md"
    // this command looks nonsense without `exec` nor `prompt` but ... the markdown will be subsituted by bash before rendering
    // that means any `$(...)`/$VARIABLE expression will be replaced by the computed value
    // example : if your markdown contains `$(uname -a)` it will be rendered as whatever `uname -a` returns on your machine
  },
  {
    "caption": "Exit",
    // help for this command is inline markdown
    "help": "# Exit\n\nQuits the program",
    // exec contains a function call exported by shaunch forcing shaunch to exit when this command gets trigged (by hitting `Enter`)
    "exec": "shaunch: exit"
  },
  {
    "caption": "Backup",
    "help": "# Backup\n\nstarts the backup.\n\nHit enter to copy the command to the next prompt",
    // if this action gets trigegred, the prompt value will be written after the next terminal prompt so that the user can decide if he wahts to execute the command by manually confirm with `Enter` in the terminal
    "prompt": "./backup.sh"
  }
]
```

## Populating commands by reading a directory containing scripts and markdown files

If the path provided by option `-c` points to an directory shaunch will populate all executables and same named markdown files into JSON and render them.

see [static directory example](https://github.com/lgersman/pnpmkambrium/tree/develop/packages/docker/shaunch/examples/commands-by-directory)

## Dynamic commands evaluation

If the path provided by option `-c` points to an executable file, it will be executed. Shaunch expects that the script returns the Shaunch JSON configuration.

Using this feature you can provide dynamic command configurations generated by a script.

see [dynamic script example(s)](https://github.com/lgersman/pnpmkambrium/tree/develop/packages/docker/shaunch/examples/commands-by-script)

### `exec` property

Shaunch exposes some Bash functions callable in scripts/code of the `exec` command property using `shaunch: [operation]`

Available operations :

- `exit` will exit shaunch

  example: `shaunch: exit`

## `prompt` property

The prompt property allows you to define a command placed at the next prompt after shaunch exited.

If `prompt` is given, hitting `Enter` will exit Shaunch and place the `prompt` value at your next prompt.

# Usage

```
docker run -it --rm -v $(pwd)/your-shaunch-app-dir:/app pnpmkambrium/shaunch
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

  - by providing a shell snippet to execute : `./packages/docker/shaunch/bin/shaunch.sh -- 'yq -o=json . ./packages/docker/shaunch/examples/commands-by-script/commands-by-script.yml'` (requires [yq](https://mikefarah.gitbook.io/yq/))

- build docker image : `make packages/docker/shaunch/`

- using dockerized shaunch :

  - by browsing a directory : `docker run -it --rm -v $(pwd)/packages/docker/shaunch/examples/commands-by-directory:/app pnpmkambrium/shaunch`

  - by executing a script: `docker run -it --rm -v $(pwd)/packages/docker/shaunch/examples/commands-by-script:/app pnpmkambrium/shaunch -c /app/commands-by-script`

- build using the docker-compose file : `docker compose -f packages/docker/shaunch/docker-compose.yml build`

- run `docker-compose run --rm main`

# Limitations

- The local bash script works right now only on amd64 linux machines because i did not figured out a way to install it's dependencies in a cross platform manner.

  @TODO: This can be easily fixed by downloading the correct [fzf](https://github.com/junegunn/fzf) and [batcat](https://github.com/sharkdp/bat) binaries depending on the platform.

- writing to the next prompt using the `prompt` property will not work when executed from docker

# FAQ

- How can I exit `shaunch` from a command ?

  Just call `shaunch: exit` in your command script (see [dynamic configuration example](https://github.com/lgersman/pnpmkambrium/tree/develop/packages/docker/shaunch/examples/commands-by-script)). The `shaunch` command is a exported function exporting some operations like exiting.
