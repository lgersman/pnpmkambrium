/*#
#  default nano-staged configuration
# 
# this file is usually referenced in your own top level .nano-staged.mjs.
#
# ```
# export { default as default } from '@pnpmkambrium/core/presets/default/.nano-staged.mjs';
# ```
#
# You can remove it in case you don't want to lint using nano-staged
#*/
export default {
  '*': 'make lint-fix',
};
