const branch = process.env.GITHUB_REF;
const github_sha = process.env.GITHUB_SHA;
const prerelease_suffix = github_sha.substring(0, 7);

const changelogUpdatePlugin = ["@semantic-release/changelog", {
  "branches": [
    "main"
  ],
  "changelogFile": "CHANGELOG.md",
  "changelogTitle": "# Changelogs"
}];

const config = {
  plugins:
    [
      ["@semantic-release/commit-analyzer"],
      ["@semantic-release/release-notes-generator", {
        "preset": "conventionalcommits",
        "presetConfig": {
          "issueUrlFormat": "https://croesus-support.atlassian.net/browse/{{id}}"
        }
      }],
      changelogUpdatePlugin,
      ["@semantic-release/github"],
      ["@semantic-release/npm", {
        "npmPublish": false,
      }],
      ["@semantic-release/exec", {
        "successCmd": 'echo "RELEASED_VERSION=${nextRelease.version}" >> $GITHUB_ENV',
      }],
      ["@semantic-release/git", {
        "assets": ["CHANGELOG.md", "package.json"],
        "message": "release: cut the ${nextRelease.version} release"
      }]
    ],
  branches: [
    "main",
    { name: "dev/+([a-zA-Z])?(-)+([0-9])", prerelease: "${name.replace(/^(dev\\/)([a-zA-Z]+)([-]?)([0-9]+)/g, '$2$4').toUpperCase()}-" + prerelease_suffix },
    { name: "dev/*", prerelease: "${name.replace(/^dev\\//g, '').toLowerCase()}-" + prerelease_suffix },
    { name: "feature/+([a-zA-Z])?(-)+([0-9])", prerelease: "${name.replace(/^(feature\\/)([a-zA-Z]+)([-]?)([0-9]+)/g, '$2$4').toUpperCase()}-" + prerelease_suffix },
    { name: "feature/*", prerelease: "${name.replace(/^feature\\//g, '').toLowerCase()}-" + prerelease_suffix },
  ],
  tagFormat: 'v${version}'
}

// Only update changelog when released from main (until https://github.com/semantic-release/changelog/pull/157)
if (!branch || branch !== 'refs/heads/main') {
  const changelogUpdatePluginIndex = config.plugins.indexOf(changelogUpdatePlugin);
  if (changelogUpdatePluginIndex > -1) {
    config.plugins.splice(changelogUpdatePluginIndex, 1);
  }
}

module.exports = config
