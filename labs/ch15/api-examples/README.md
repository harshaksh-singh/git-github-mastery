# Practice files for `--jq` expressions

`pulls-sample.json` is a practice document written for this course. It is **not** output
from GitHub. It has the shape of the response of `GET /repos/{owner}/{repo}/pulls`: an array
of objects, with field names (`number`, `title`, `state`, `draft`, `created_at`,
`user.login`, `base.ref`, `head.ref`) that were checked against the example response in the
REST reference on 2 October 2026
(<https://docs.github.com/en/rest/pulls/pulls#list-pull-requests>). The values are
invented, and a real response has many more fields.

The demo `labs/ch15/jq-rehearsal.sh` runs `jq` filters on it, so that the filters can be
practised offline before Lab 25.2 runs them with `gh api --jq` against a real repository.
