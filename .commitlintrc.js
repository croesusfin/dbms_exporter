module.exports = {
  extends: ['@commitlint/config-angular'],
  rules: {
    'type-enum': [2, 'always', ['build', 'chore', 'ci', 'docs', 'feat', 'fix', 'refactor', 'style', 'test', 'release']],
  },
};
