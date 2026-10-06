# Module 25 lab answers: GitHub CLI and API

> **Baseline.** Git 2.55.0 and GitHub CLI 2.88.1 on macOS; GitHub facts as of 1 October 2026. These are answers to the "Questions" of each lab in the [Module 25 lab manual](../lab-manual/m25-github-cli-api.md). Write your own answers first. Nothing here was captured from GitHub: where an answer depends on what you saw, it says what the documentation leads you to expect.

## Lab 25.1: A full feature cycle with `gh`

1. **Why `-d` refused.** `git branch -d` deletes a branch only if its tip is merged into its upstream branch, or into `HEAD` when it has no upstream or the upstream ref no longer exists. After the squash merge, `main` contains one new commit with the same content; your two commits are not its ancestors. After `git fetch --prune` the upstream ref was gone, so Git compared with `HEAD`, found the branch "not fully merged", and refused. Before the prune, the stale remote-tracking ref `origin/feature/list-names` still contained your commits, and `-d` would have deleted the branch with a warning. The replay tries exactly that in a copy of the clone:

<!-- snippet: ch15/lab-25-1-feature-cycle/20-what-if-d-before-prune -->
```text
# In a copy of your clone, made before the clean-up: the same deletion without pruning first.
$ cd ../../you-copy/practice-repo
$ git branch -vv
  feature/list-names c0b29a8 [origin/feature/list-names] Document names()
* main               9477a3f [origin/main] Add names() to list registered prompts (#2)
$ git branch -d feature/list-names
warning: deleting branch 'feature/list-names' that has been merged to
         'refs/remotes/origin/feature/list-names', but not yet merged to HEAD
Deleted branch feature/list-names (was c0b29a8).
[exit status: 0]
```
<!-- /snippet -->

   Both outcomes are correct by Git's rule. Neither tells you whether the content is on `main`; `git diff --quiet main feature/list-names` does.
2. **Author and committer of the squash commit.** `git log -1 --format=fuller main` shows both fields, and `git log -1 --show-signature main` the signature. According to GitHub's documentation, a commit created by "Squash and merge" is created by GitHub on its servers and signed by GitHub, so expect GitHub in the committer field and yourself as author. The Phase 0 report marks one detail as unverified against the current documentation: who is recorded as author of a squash commit when a pull request has commits by several people. Your pull request had one author, so your observation settles your case and not that one.
3. **Why the issue closed.** The description contained a closing keyword with the issue's number (`Closes #N`), and the pull request targeted the repository's default branch; then it was merged. It would have failed with a base other than the default branch, where keywords are ignored, or with a keyword that does not parse, for example a missing `#` or the wrong number.
4. **The two tags.** Expect `tag` for `v0.1.0`, which you created with `git tag -a`, and `commit` for `v0.1.1`, which GitHub created for the release: a lightweight tag. If you saw that, you have confirmed what Chapter 15 could only infer. Both `git describe` and `git describe --tags` printed `v0.1.0`: the two tags name the same commit, plain `describe` considers annotated tags only, and with `--tags` an annotated tag still takes precedence over a lightweight one on the same commit. Had `main` moved before the release was created, `--tags` would have found `v0.1.1` on the newer commit and the two commands would disagree, as in section 15.12.
5. **Two deletions.** `gh release delete --cleanup-tag` deleted the release and the tag on GitHub. Your clone had fetched the tag in the meantime, and nothing on the server deletes refs in your clone. Without `git tag -d v0.1.1`, your next `git push --tags` would have created the tag on GitHub again, and with it a trigger for any workflow that runs on tags.
6. **Roles.** With Read you could have created the issue and reviewed, but not pushed the branch to the organization's repository (you would work from a fork), not merged, and not created the release; applying the label needs Triage. With Triage you could label, assign and close issues and request reviews, and still not push, merge or release. Write is the first role that can do the whole cycle (Chapter 15, section 15.4).
7. **Why GitHub could not help.** The branch was never pushed, so no ref, no object and no pull request for it existed on GitHub. After `git branch -D`, the commit still existed in exactly one place, your clone's object database, and one thing still named it: the reflog of `HEAD`. The branch's own reflog was deleted with the branch. An unreachable commit that only a reflog names lives until the reflog entry expires and garbage collection runs (Chapter 13).

## Lab 25.2: Queries with `gh api`

1. **`gh pr list` or `gh api`.** `gh pr list --json ... --jq ...` is the right tool when the fields you need are among those it offers: it handles the request shape and pagination limits for you and reads well. `gh api` is for everything else: an endpoint gh has no command for (rulesets, milestones), exact REST semantics, an explicit API version, or full control over pagination. In a script use either with `--json` or `--jq`, never the human-readable table.
2. **`-X GET`.** `-f state=all` adds a request parameter, and `gh api --help` states that adding parameters switches the method to `POST` unless `--method GET` is given. The rule: every `gh api` command with `-f` or `-F` names its method.
3. **All 240 items.** `--paginate` follows the `link` header until the last page; with the default page size that is eight requests. A larger page, `-F per_page=100` (the documented maximum), needs three. Use both together: fewer requests, and correctness that does not depend on the size of the list. `--slurp` additionally wraps the pages into one array when you need to count or sort across pages.
4. **After 10 March 2028.** Version `2022-11-28` reaches its end of support on that date. GitHub's page says that requests without a version header then default to the next oldest supported version, so an unversioned script silently starts to get the behavior of a newer version, including its breaking changes. A long-lived script should send `X-GitHub-Api-Version` explicitly, be tested against the version it names, and be reviewed when a `Deprecation` or `Sunset` response header appears.
5. **Counting.** Every REST request counts once against the core bucket, and a paginated command counts once per page. `GET /rate_limit` is the request documented as not counting against the primary limit. The GraphQL call is accounted for in a separate bucket with its own point system. Compare `used` before and after to see your own number.
6. **A `404` for a repository that exists.** In this order: which account and token is `gh` using (`gh auth status`, and is `GH_TOKEN` set in the environment); is the owner and name spelled exactly; if the token is fine-grained, does it include that repository and has the organization approved it; does the organization use SAML single sign-on that the credential is not authorized for; and last, are you a member, on a team with access, or a collaborator at all. GitHub answers `404` to all of these on purpose (Chapter 16, section 16.19).
7. **API or documentation page.** Neither is more trustworthy than the other. Both arrive over TLS from hosts whose certificates your machine validates: `api.github.com` in one case, `docs.github.com` in the other. Whoever could tamper with one connection could tamper with the other. What the API adds is a second, independent path and a machine-readable form, which is what a provisioning script should use to install `known_hosts` lines.
