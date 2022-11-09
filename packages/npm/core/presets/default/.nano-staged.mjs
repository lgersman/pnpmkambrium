/*#
#  default .nano-staged.mjs configuration
# 
# this file is usually referenced in your own top level .nano-staged.mjs.
#
# ```
# export { default as default } from '@pnpm-kambrium/core/presets/default/.nano-staged.mjs';
# ```
#
# You can remove it in case you don't need to lint css files.
#*/
export default {
  '*': 'pnpm make lint-fix',
};
