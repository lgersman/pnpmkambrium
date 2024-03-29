# wordpress wp-env related shell helper functions

#
# transforms docker volumes references from the docker-compose.yml of wp-env to vscode launch pathmappings
#
# @param $1 the DOCKER_CONTAINER_PATH_MAPPINGS
#
function kambrium.wp-env.docker-volumes-to-launch-pathmappings() {
  readonly DOCKER_CONTAINER_PATH_MAPPINGS="$1"

  LAUNCH_CONFIGURATION_PATH_MAPPINGS='{}'
  for DOCKER_CONTAINER_PATH_MAPPING in ${DOCKER_CONTAINER_PATH_MAPPINGS[@]}; do
    # echo "DOCKER_CONTAINER_PATH_MAPPING=$DOCKER_CONTAINER_PATH_MAPPING"

    LOCAL_PATH="${DOCKER_CONTAINER_PATH_MAPPING%:*}"
    CONTAINER_PATH="${DOCKER_CONTAINER_PATH_MAPPING##*:}"

    # replace workspace root with "${workspaceRoot}" in variable LOCAL_PATH
    LOCAL_PATH="${LOCAL_PATH/$(pwd)/\${workspaceRoot\}}"

    LAUNCH_CONFIGURATION_PATH_MAPPINGS=$(
      jq --arg key "$CONTAINER_PATH" --arg value "$LOCAL_PATH" '{($key): ($value)} + .' <<< "$LAUNCH_CONFIGURATION_PATH_MAPPINGS"
    )
  done

  jq '.' <<< "$LAUNCH_CONFIGURATION_PATH_MAPPINGS"
}

#
# generates the vscode launch confguration file for the installed wp-env
#
# @param $1 the WP_ENV_INSTALL_PATH
#
function kambrium.wp-env.generate_launch.json() {
  readonly WP_ENV_INSTALL_PATH="$1"

  DEVELOPMENT_LAUNCH_PATH_MAPPINGS=$(yq '.services.wordpress.volumes.[]' "${WP_ENV_INSTALL_PATH}/docker-compose.yml")
  DEVELOPMENT_LAUNCH_PATH_MAPPINGS=$(kambrium.wp-env.docker-volumes-to-launch-pathmappings "$DEVELOPMENT_LAUNCH_PATH_MAPPINGS")

  TESTS_LAUNCH_PATH_MAPPINGS=$(yq '.services.tests-wordpress.volumes.[]' "${WP_ENV_INSTALL_PATH}/docker-compose.yml")
  TESTS_LAUNCH_PATH_MAPPINGS=$(kambrium.wp-env.docker-volumes-to-launch-pathmappings "$TESTS_LAUNCH_PATH_MAPPINGS")

  cat << EOF > '.vscode/launch.json'
{
  // THIS FILE IS MACHINE GENERATED by pnpmkambrium!  DO NOT EDIT!
  // If you need to confgure additional launch configurations consider defining them in a vscode *.code-workspace file
  "version": "0.2.0",
  "configurations": [
    {
      "name": "wp-env/phpunit",
      "type": "php",
      "request": "launch",
      "port": 9003,
      "stopOnEntry": false, // set to true for debugging this launch configuration
      "log": false,         // set to true to get extensive xdebug logs
      // pathMappings derived from wp-env generated docker-compose.yml
      "pathMappings": ${DEVELOPMENT_LAUNCH_PATH_MAPPINGS}
    }
  ]
}
EOF
}
