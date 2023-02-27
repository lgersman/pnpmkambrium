this directory contains a 2 working shaunch examples.

- if the `commands-by-script` bash file gets provided to shaunch,

  ```
  ./packages/docker/shaunch/bin/shaunch.sh -c ./packages/docker/shaunch/examples/commands-by-script/commands-by-script
  ```

  it will be executed and the resulting json
  will be interpreted to display the shaunch menu.

- if shaunch is started using the `--` option it will execute the bash snippet argument

  ```
  ./packages/docker/shaunch/bin/shaunch.sh -- 'yq -o=json . ./packages/docker/shaunch/examples/commands-by-script/commands-by-script.yml'
  ```
