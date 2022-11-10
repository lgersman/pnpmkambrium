/*#
# default git-cz / commitizen configuration
# 
# this file is usually referenced in your own top level changelog.config.js.
#
# ```
# const settings = require('@pnpm-kambrium/core/presets/default/changelog.config.js');
# module.exports = {
#   ...settings,
# };
# ```
#
# You can remove it in case you don't use git-cz / commitizen
#*/
module.exports = {
  disableEmoji: true,
  format: '{type}{scope}: {subject}',
  list: ['test', 'feat', 'fix', 'chore', 'build', 'docs', 'refactor', 'style', 'ci', 'perf', 'wip'],
  maxMessageLength: 64,
  minMessageLength: 3,
  questions: ['type', 'scope', 'subject', 'body', 'breaking', 'issues', 'lerna'],
  scopes: ['', ...JSON.parse(process.env['PNPM_WORKSPACE_PACKAGES'] ?? '[]')],
  types: {
    chore: {
      description: 'Auxiliary tool changes',
      value: 'chore',
    },
    wip: {
      description: 'work in progress',
      value: 'wip',
    },
    build: {
      description: 'Build process changes',
      value: 'build',
    },
    ci: {
      description: 'CI related changes',
      value: 'ci',
    },
    docs: {
      description: 'Documentation only changes',
      value: 'docs',
    },
    feat: {
      description: 'A new feature',
      value: 'feat',
    },
    fix: {
      description: 'A bug fix',
      value: 'fix',
    },
    perf: {
      description: 'A code change that improves performance',
      value: 'perf',
    },
    refactor: {
      description: 'A code change that neither fixes a bug or adds a feature',
      value: 'refactor',
    },
    release: {
      description: 'Create a release commit',
      value: 'release',
    },
    style: {
      description: 'Markup, white-space, formatting, missing semi-colons...',
      value: 'style',
    },
    test: {
      description: 'Adding missing tests',
      value: 'test',
    },
  },
};
