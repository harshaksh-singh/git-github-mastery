# Action pins used in this course

Every workflow in this course references third-party and GitHub-owned actions by **full commit SHA**, with the version as a trailing comment. A tag can be moved by whoever controls the action's repository; a full commit SHA cannot. Chapter 21 explains the incidents that made this the rule.

These pins were read on **1 October 2026** with an anonymous `git ls-remote --tags https://github.com/<owner>/<repo>`. For annotated tags the SHA is the commit the tag points at (the peeled `^{}` line), which is what a workflow must reference.

| Action | Version | Commit SHA |
|---|---|---|
| actions/checkout | v7.0.1 | `3d3c42e5aac5ba805825da76410c181273ba90b1` |
| actions/setup-python | v7.0.0 | `5fda3b95a4ea91299a34e894583c3862153e4b97` |
| actions/setup-java | v6.0.1 | `de7274f081f381c8f8158605e0321c36c376e2e6` |
| actions/setup-node | v7.0.0 | `820762786026740c76f36085b0efc47a31fe5020` |
| actions/cache | v6.1.0 | `55cc8345863c7cc4c66a329aec7e433d2d1c52a9` |
| actions/upload-artifact | v7.0.1 | `043fb46d1a93c77aae656e7c1c64a875d1fc6a0a` |
| actions/download-artifact | v8.0.1 | `3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c` |
| actions/github-script | v9.0.0 | `3a2844b7e9c422d3c10d287c895573f7108da1b3` |
| actions/attest | v4.2.2 | `1e69f48acb82d1966a394da916b4c1698aa569d6` |
| actions/dependency-review-action | v5.0.0 | `a1d282b36b6f3519aa1f3fc636f609c47dddb294` |
| actions/configure-pages | v6.0.0 | `45bfe0192ca1faeb007ade9deae92b16b8254a0d` |
| actions/upload-pages-artifact | v5.0.0 | `fc324d3547104276b827a68afc52ff2a11cc49c9` |
| actions/deploy-pages | v5.0.1 | `368f82528645a54fb793d4d04e342629a3f51346` |
| astral-sh/setup-uv | v10.2.0 | `c18668ad3cf93ea998bef934396af7bb5c839dc7` |
| docker/login-action | v4.6.0 | `dbcb813823bdd20940b903addbd779551569679f` |
| docker/setup-buildx-action | v4.4.1 | `f87e5991a6d7451dcb8d9637bfbc97413f497069` |
| docker/setup-qemu-action | v4.4.0 | `99012661954931238ded8c8b007157a8430204e1` |
| docker/build-push-action | v7.4.0 | `c3c9e263c25d99ce0380d002d59b67737d91b0dc` |
| docker/metadata-action | v6.2.0 | `dc802804100637a589fabce1cb79ff13a1411302` |
| github/codeql-action | v4.38.2 | `2892aa5e19bbd11bc0cff5427e3b750a04d9e3c2` |
| softprops/action-gh-release | v3.0.3 | `efb35369e0ad2afab669f228072c1b0d510eae64` |
| gradle/actions | v6.4.0 | `3f5f9adaf7d9fecd50b5935e54106014257a94e6` |
| aws-actions/configure-aws-credentials | v6.3.0 | `e1253824e5c10ff9df46874f81ed3ec929e19cfd` |
| google-github-actions/auth | v3.0.0 | `7c6bc770dae815cd3e89ee6cdf493a5fab2cc093` |
| azure/login | v3.1.0 | `a641126d1b8aa4d1fa005f4f92df94a3a4c4c906` |

## How to write a pin

```yaml
- uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
```

## How to re-verify a pin yourself

Run this before you trust any pin, including the ones above. It needs no login.

```bash
git ls-remote --tags https://github.com/actions/checkout 'refs/tags/v7.0.1*'
```

If the tag is annotated you see two lines; the one ending in `^{}` is the commit. If it is a lightweight tag you see one line and it is the commit.

## Keeping pins current

Pins go stale on purpose: nothing changes until you change it. Let Dependabot propose updates by adding the `github-actions` ecosystem to `.github/dependabot.yml`; it updates the SHA and the version comment together. Chapter 21 covers the configuration and the cooldown setting.
