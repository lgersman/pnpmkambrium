/*#
#  default prettier configuration
# 
# this file is usually referenced in your own top level .prettierrc.js.
#
# ```
# const settings = require('@pnpm-kambrium/core/presets/default/.prettierrc.js');
# module.exports = {
#   ...settings,
# };
# ```
#
# You can remove it in case you don't use prettier
#*/
module.exports = {
  semi: true,
  tabWidth: 2,
  singleQuote: true,
  printWidth: 120,
  trailingComma: 'all',
  overrides: [
    /*
      # {
      #   "files": ["*.json5"],
      #   "options": { "singleQuote": false, "quoteProps": "preserve" },
      # },
      */
    { files: ['*.yml'], options: { singleQuote: false } },
  ],
};
