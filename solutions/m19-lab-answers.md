# Module 19 lab answers: GitHub the platform

> **Baseline.** Git 2.55.0 and GitHub CLI 2.88.1 on macOS; GitHub facts as of 1 October 2026. These are answers to the "Questions" of each lab in the [Module 19 lab manual](../lab-manual/m19-github-platform.md). Write your own answers first. Where an answer depends on what GitHub showed you, it says what to expect according to the documentation; nothing here was captured from GitHub.

## Lab 19.1: The practice organization and a repository with health files

1. **Git data and GitHub objects.** Git data: one commit, its trees, the blobs of fourteen files, `refs/heads/main` in your clone and on the server, and in your clone only, `refs/remotes/origin/main` and the remote and upstream configuration. GitHub objects: the organization, the repository record with its name, description and visibility, the settings you changed (delete branch on merge, wiki and projects off), your role in it, and what GitHub derives for display: the detected license and the community profile. The issue forms belong in the Git column. They are tracked files that GitHub reads from the default branch. That is the interesting answer because they configure the platform and yet travel with every clone, are changed by commits, and can be reviewed in a pull request; the settings cannot.
2. **Three things in one command.** It created the repository on GitHub through the API, added the remote `origin` to your local repository, and pushed your commits. The Git part is `git remote add origin <URL>` followed by `git push origin main`; the replay uses `git push -u`, which also sets the upstream. Whether gh set the upstream for you is visible in `git status -sb`: a line `## main...origin/main` means it is set.
3. **Why `main` is the default branch.** Two things had to agree. GitHub creates a repository with the default branch name that your account or organization has configured for new repositories, `main` unless someone changed it; the help text of `gh repo create` says so and links the setting. And you pushed a branch with that name, because you ran `git init -b main`. `gh repo view --json defaultBranchRef` shows the result. Git has no say in it: a default branch is a GitHub setting, represented on the server as the branch that `HEAD` names.
4. **Delete branch on merge.** It is a field of the repository record on GitHub, readable with `gh repo view --json deleteBranchOnMerge`. After a pull request merges, GitHub deletes the pull request's head branch on the server. It does not delete your local branch, and it does not delete your remote-tracking ref `origin/<branch>`, which goes only when you run `git fetch --prune`. Lab 25.1 shows all three.
5. **Base permission.** The value is the one you read on the Member privileges page. With Read, a new member can clone, open issues, comment, fork and submit a review that does not count toward a requirement, and cannot push. For this public repository that is what everyone on the internet can do anyway. For a private repository the base permission is what makes the difference: Read would let every member clone it on day one, and "none" would require an explicit grant through a team or directly (Chapter 15, section 15.4).
6. **Who wrote the error.** Both lines begin with `error:` and none begins with `remote:`, so they come from your Git. `src refspec main does not match any` means that Git looked for something named `main` on the source side of the push, in your own repository, and found no such ref. It failed before it opened a connection.
7. **The license.** The text came from GitHub's license templates, fetched through the API by `gh repo license view`. Until you ran `git add` it was an untracked file. It became part of the repository's history with your commit, and GitHub detected it only after the push, by reading the file on the default branch.

## Lab 19.2: An inventory of Git data and GitHub objects

The table:

| Thing | Layer | Command that proves it | In a mirror? |
|---|---|---|---|
| the commit on `main` | Git: an object | `git cat-file -t <ID>` | yes |
| the branch `main` on the server | Git: a ref on the server | `git ls-remote origin` | yes |
| `origin/main` in your clone | Git, local to your clone | `git for-each-ref refs/remotes` | no: it exists only in your clone |
| an annotated tag | Git: a ref and a tag object | `git cat-file -p v0.1.0` | yes |
| the issue forms | Git data that GitHub interprets | `git ls-files .github` | yes |
| the issue you created | GitHub object | `gh issue list`; absent from `git ls-remote` | no |
| the label `documentation` | GitHub object | `gh label list` | no |
| the repository's visibility | GitHub setting | `gh repo view --json visibility` | no |
| "delete branch on merge" | GitHub setting | `gh repo view --json deleteBranchOnMerge` | no |
| your role on the repository | GitHub object | `gh api repos/{owner}/{repo} --jq .permissions` | no |
| the reflog of your clone | Git, local only | `git reflog` | no |
| a star | GitHub object | `gh repo view --json stargazerCount` | no |

1. **Two names for one commit.** Your clone fetches with `+refs/heads/*:refs/remotes/origin/*`: the server's branches are filed under `refs/remotes/origin/`, and your own `refs/heads/` is yours. A mirror fetches with `+refs/*:refs/*`: every ref keeps its name, so the server's `refs/heads/main` is the mirror's `refs/heads/main`. That is why a mirror can be pushed back with `--mirror` and reproduce the server exactly (Chapter 12, section 12.3).
2. **`Fixes #12` on GitHub.** GitHub interprets closing keywords in commit messages when the commit reaches the default branch: an issue 12 in that repository would be closed and would show the reference. If no issue or pull request has the number 12, there is nothing to link and the words stay words. In the sandbox there is no tracker at all, and Git stored the text without interpreting it.
3. **What changes `git ls-remote`.** Only something that creates, moves or deletes a ref on the server: a pushed branch or tag, a merge, a deleted branch, or a pull request, for which GitHub creates a `refs/pull/N/head` ref. An issue, a label, a comment or a setting changes no ref.
4. **Missing after a recovery on GitHub.** Open pull requests, the default branch setting, release notes and deploy keys would be missing: all four are GitHub objects. Tags and the `.github` directory would be back, because they are Git data. The commits of open pull requests would be back only if a branch still named them.
5. **In neither.** Your clone's reflog and its configuration (remote URLs, upstream settings), and equally the index, stashes, hooks and ignored files such as `.env`. They are local to one clone: no mirror receives them and GitHub never had them.
6. **The nightly mirror.** "A mirror clone backs up every commit, branch and tag, which protects the code and its history. It contains no issue, pull request discussion, review, release, rule, role or secret, so call it the backup of our Git data, and plan a separate export through the API for the rest."
