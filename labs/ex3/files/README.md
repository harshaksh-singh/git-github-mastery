# Practice documents for the exercises of Modules 19 to 34

The JSON files in this directory are **practice documents written for this course**. They are
not output from GitHub. They exist so that `jq` filters, which `gh api --jq` also accepts, can
be rehearsed offline with real `jq` output.

- `pulls-pages.json`: two "pages" of a pull request list, shaped like the result of
  `gh api --paginate --slurp` (an array of pages). The field names (`number`, `title`, `state`,
  `draft`, `created_at`, `user.login`, `base.ref`, `head.ref`) are the ones used in
  `labs/ch15/api-examples/pulls-sample.json`, which Chapter 15, section 15.17 checked against
  the REST reference.
- `rulesets-list.json`: a list of rulesets with the fields `id`, `name`, `target` and
  `enforcement`, the fields that Chapter 15, section 15.17 and Chapter 18, section 18.18 use.
