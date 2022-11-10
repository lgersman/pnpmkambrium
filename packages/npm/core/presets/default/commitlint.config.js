/*#
# default commitlint configuration
#
# this file is usually referenced in your own top level commitlint.config.js.
#
# ```
# extends:
#   - "@pnpm-kambrium/core/presets/default/commitlint.config.js"
# ```
#
# You can remove it from there depending on your needs.
#*/
const changelogConfig = require('./changelog.config.js');

module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [2, 'always', changelogConfig.list],
  },
};
