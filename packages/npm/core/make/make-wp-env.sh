# wordpress wp-env related shell helper functions

function kambrium.wp-env.generate_launch.json() {
# # nullglob is needed because we want to skip the loop if no plugins/theme packages are found
# shopt -s nullglob

# PLUGINS='[]'
# for plugin in packages/wp-plugin/*/; do
#   PLUGINS=$$(echo "$$PLUGINS" | jq --arg plugin "./$$plugin" '. += [$$plugin]')
# done

# THEMES='[]'
# for theme in packages/wp-theme/*/; do
#   THEMES=$$(echo "$$THEMES" | jq --arg theme "./$$theme" '. += [$$theme]')
# done

# jq -n \
#   --arg wordpress_image "WordPress/WordPress#$${REQUIRES_AT_LEAST_WORDPRESS_VERSION:-latest}" \
#   --arg phpVersion "$${PHP_VERSION:-8.0}" \
#   --argjson plugins "$${PLUGINS}" \
#   --argjson themes "$${THEMES}" \
#   '{core: $$wordpress_image, phpVersion: $$phpVersion, plugins : $$plugins, themes : $$themes}' \
# > $@


  cat << EOF | tee '.vscode/launch.json'
{
  // THIS FILE IS MACHINE GENERATED!  DO NOT EDIT!
  // the template will be substituded with the active wp-env configuration (see Makefile)
  // If you want to make changes -=> edit the "launch.json.template" file
  "version": "0.2.0",
  "configurations": [
    {
      "name": "impex xdebug (cli)",
      "type": "php",
      "request": "launch",
      "program": "\${workspaceFolder}/impex-cli/impex-cli.php",
      "cwd": "\${workspaceFolder}/impex-cli",
      "port": 0,
      "runtimeArgs": ["-dxdebug.start_with_request=yes"],
      "env": {
        "XDEBUG_MODE": "debug,develop",
        "XDEBUG_CONFIG": "client_port=\${port}"
      },
      "args": [
        "import",
        "-profile=all",
        "-username=admin",
        "-password=password",
        "-verbose",
        "-rest-url=http://localhost:8888/wp-json",
        "-options={\"impex-import-option-cleanup_contents\" : true}",
        "./tests/fixtures/simple-import"
      ]
    },
    {
      "name": "impex xdebug (phpunit)",
      "type": "php",
      "request": "launch",
      "port": 9004,
      //"stopOnEntry": true,
      //"log": true,
      "pathMappings": {
        // imported from .wp-env.override.json by Makefile
    			"/var/www/html/wp-content/plugins/cm4all-wordpress": "../cm4all-wordpress/packages/wordpress/wp-content/plugins/cm4all-wordpress",
  			"/var/www/html/wp-content/themes/trinity-core": "../cm4all-wordpress/packages/wordpress/wp-content/themes/trinity-core",
  			"/var/www/html/wp-content/plugins/": "../cm4all-thirdparty-plugin-helper/packages/wordpress/wp-content/plugins/cm4all-thirdparty-plugin-helper",
  "impex-cli": "./impex-cli",
  			"/var/www/html/wp-content/plugins/cm4all-wordpress/scripts/wp-env/generate-block-list.php": "../cm4all-wordpress/scripts/build/generate-block-list.php",
        // --
        "/var/www/html/wp-content/plugins/cm4all-wp-impex": "\${workspaceRoot}/plugins/cm4all-wp-impex",
        "/var/www/html/wp-content/plugins/cm4all-wp-impex-example": "\${workspaceRoot}/plugins/cm4all-wp-impex-example",
        "/var/www/html": "\${workspaceRoot}/wp-env-home/44dfc68bc95acc501ec8fa3394691608/WordPress"
      }
    },
    {
      "name": "impex xdebug (wp-env)",
      "type": "php",
      "request": "launch",
      "port": 9003,
      //"stopOnEntry": true,
      //"log": true,
      "pathMappings": {
        // imported from .wp-env.override.json by Makefile
        // (replace "../" with "\${workspaceRoot}/../" for paths outside the project directory)
    			"/var/www/html/wp-content/plugins/cm4all-wordpress": "../cm4all-wordpress/packages/wordpress/wp-content/plugins/cm4all-wordpress",
  			"/var/www/html/wp-content/themes/trinity-core": "../cm4all-wordpress/packages/wordpress/wp-content/themes/trinity-core",
  			"/var/www/html/wp-content/plugins/": "../cm4all-thirdparty-plugin-helper/packages/wordpress/wp-content/plugins/cm4all-thirdparty-plugin-helper",
  "impex-cli": "./impex-cli",
  			"/var/www/html/wp-content/plugins/cm4all-wordpress/scripts/wp-env/generate-block-list.php": "../cm4all-wordpress/scripts/build/generate-block-list.php",
        // --
  			"/var/www/html/wp-content/plugins/cm4all-wp-impex": "\${workspaceRoot}/plugins/cm4all-wp-impex",
  			"/var/www/html/wp-content/plugins/cm4all-wp-impex-example": "\${workspaceRoot}/plugins/cm4all-wp-impex-example",
        "/var/www/html/wp-content/plugins": "\${workspaceRoot}/wp-env-home/44dfc68bc95acc501ec8fa3394691608",
        "/var/www/html/wp-content/themes": "\${workspaceRoot}/packages/wordpress/wp-content/themes",
        "/var/www/html/wp-config.php": "\${workspaceRoot}/wp-env-home/44dfc68bc95acc501ec8fa3394691608/WordPress/wp-config.php",
        "/var/www/html": "\${workspaceRoot}/wp-env-home/44dfc68bc95acc501ec8fa3394691608/WordPress"
      }
    }
  ]
}
EOF

  echo "hey !!!!"
}



