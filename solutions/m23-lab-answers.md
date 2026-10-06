# Module 23 lab answers: Governance: rulesets, branch protection, and CODEOWNERS

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. These are answers to the "Questions" of each lab in the [Module 23 lab manual](../lab-manual/m23-governance.md), followed by the answers to the pattern exercises of [Chapter 19](../textbook/ch19-codeowners.md), section 19.16. Write your own answers first. Answers about Part B rest on GitHub's documentation, cited in the manual and in [Chapter 18](../textbook/ch18-branch-protection.md); where they depend on what you observed, the answer says what to compare your notes with.

## Lab 23.1: A ruleset on the default branch

1. **Client options.** None of them. `--force` and `--force-with-lease` switch off or refine checks that your own Git makes before it sends the proposal. The refusals came from the server, which evaluates the proposal itself. That is why the transcript says `! [remote rejected]`, not `! [rejected]`.
2. **Values per rule.** Restrict deletions: the new ID (all zeros) and the ref name. Block force pushes: old and new, through the ancestry test `git merge-base --is-ancestor old new`. Linear history: the range `old..new`, searched for commits with two parents. Restrict updates on tags: the old ID (not all zeros means the tag exists). The ref name decides in every case whether the rule applies at all: that is the target.
3. **Squash versus merge commit.** The rule looks at commit objects, not at content. The merge commit has two parents, so `git rev-list --merges old..new` finds it. The squash commit has one parent and is an ordinary commit. Same tree, different shape.
4. **The changed message.** A different layer refused. `pre-receive hook declined` is the hook; `non-fast-forward` with `denying non-fast-forward refs/heads/main` is Git's built-in `receive.denyNonFastForwards`. The wording of a refusal tells you which layer spoke, which is the first thing to establish when a branch stays blocked after you "relaxed the rule".
5. **Owner and still refused.** Under rulesets a role grants no exemption. Only the bypass list does, and the lab's ruleset has an empty one. To allow your direct push, the ruleset would need a bypass entry for you, for the repository admin role or for organization admins. For an on-call engineer the mode "for pull requests only" is the better choice: the person can merge despite unmet rules, but must open a pull request, which leaves "a clear trail of their changes in the pull request and audit log". `always` permits silent direct pushes, and `exempt` leaves no bypass record at all.
6. **Zero approvals.** A pull request for every change: a place where checks run on the merged result, a record of what changed and why, one squash commit per change on a linear `main`, and protection from force pushes and deletion. It does not give you a second pair of eyes.
7. **Evidence.** The commit is on `main` and belongs to no pull request. The Phase 0 report lists the repository's Activity view as the place that shows pushes with the user who made them, and the organization audit log as the record of settings changes; on Enterprise Cloud the ruleset history shows the change of enforcement status. The `/rules` page shows only what is active now. A disabled ruleset leaves no warning there.

## Lab 23.2: CODEOWNERS enforcement with a second account

1. **The four paths**, by the base version of `.github/CODEOWNERS`:

| Path | Lines that match | Line that decides | Owners requested |
|---|---|---|---|
| `.github/CODEOWNERS` | 2 (`*`), 15 (`/.github/`) | 15 | `@example-org/repo-admins` |
| `config/routing.yaml` | 2, 9 (`*.yaml`) | 9 | `@example-org/platform`, `@example-org/sre` |
| `docs/README.md` | 2, 12 (`docs/*`) | 12 | `@example-org/docs` |
| `docs/runbooks/escalation.md` | 2 only | 2 | `@example-org/platform` |

   The last row is the documented behavior of `docs/*`: it matches files directly in `docs/` "but not further nested files". The older `docs/CODEOWNERS` plays no part, because `.github/CODEOWNERS` exists and is found first.
2. **The deleted line still counts.** Review requests use "the version of `CODEOWNERS` from the base branch of the pull request". Your branch's version takes effect only after it has been merged.
3. **Line 2 for a YAML file.** Git's ignore matcher descends directory by directory and stops at the first excluded directory: `config/` is matched by `*`, so the file inside is never compared with `*.yaml`. In one sentence: gitignore decides whether to enter directories, CODEOWNERS assigns owners to individual files.
4. **Layering.** One approval. "If the same rule is defined in different ways across the aggregated rulesets, the most restrictive version of the rule applies."
5. **The sole owner.** A pull request that modifies content with a code owner "must be approved by that code owner", and "pull request authors cannot approve their own pull requests". The only owner of `/router/` was the author. Your approval counted as an approval and not as the owner's.
6. **When the fix counted.** At the moment the CODEOWNERS change was merged into `main`, the base branch of the blocked pull request. Not when it was committed, pushed or approved.
7. **An invitation not yet accepted.** The second account would not have write access, and an owner with "insufficient access ... will not be assigned". The lines that name only that account are skipped. You would have seen it in the answer of the errors endpoint for your branch, and as highlighting when viewing the file on GitHub. For `/router/` the consequence is that the path falls back to the `*` line.

## Lab 23.3: Three blocked merges to diagnose

1. **"Already up to date".** `git merge main` merged your local `main`, which was one commit behind the server. The rule is about the server's branch. Fetch, then merge or rebase onto the remote-tracking branch, `origin/main`. A local branch is only as current as your last update of it.
2. **`docs/queues`.** Yes, by squash: one ordinary commit lands and the merge commit inside the branch never reaches `main`. Not by "Create a merge commit", which itself adds a merge commit. For "Rebase and merge" the documentation read for this course does not say how a branch that contains a merge commit is handled; do not rely on it.
3. **Who can report a status.** "Any person or integration with write permissions to a repository can set the state of any status check." The restriction is to select an expected GitHub App as the source of the required check; a status from anyone else then does not count.
4. **The check went missing.** `gh pr update-branch` created a new head commit, a merge of `main` into the branch. Statuses are attached to commit IDs, and "required checks must pass on the latest commit SHA". The status you reported belonged to the previous head.
5. **Preventing contradictions.** Change repository merge settings and ruleset merge methods together, in one reviewed change, and keep both as files (ruleset JSON, a script of `gh repo edit` calls). After any change, try a test pull request, and read `gh ruleset check main` next to the repository's merge settings.
6. **Observed states.** Compare with your notes. The documentation leads you to expect `BLOCKED` for case A, with `gh pr checks --required` as the most direct command; `BEHIND` for case B, where `git merge-base --is-ancestor origin/main <branch>` answers the question locally; and for case C a refusal whose cause is clearest from the error text of `gh pr merge` read next to `gh ruleset check main`.
7. **"Green and still blocked".** First the machine's own summary and the required checks on the newest commit: `gh pr view --json mergeStateStatus,reviewDecision` and `gh pr checks --required`. Second, every rule layer on the base branch: `gh ruleset check <base>` or the `/rules` page, then classic rules and organization rulesets, which you may need an administrator to read. Third, the reviews as the rules see them: dismissed as stale, given by the last pusher, missing a code owner, or an outstanding request for changes.

## Chapter 19, section 19.16: pattern exercises

The file, with the line numbers that `grep -n` printed in Lab 23.2: 2 `*`, 5 `/router/`, 6 `/router/priority.py`, 9 `*.yaml`, 12 `docs/*`, 15 `/.github/`. The last matching line decides.

1. `router/classify.py`: lines 2 and 5 match. Line 5 decides: `@example-org/routing`.
2. `router/priority.py`: lines 2, 5 and 6 match. Line 6: `@example-org/routing` and `@example-org/on-call`.
3. `router/rules/eu.yaml`: lines 2, 5 and 9 match. Line 9: `@example-org/platform` and `@example-org/sre`. The routing team is not asked, although the file is in their directory, because `*.yaml` comes later.
4. `config/routing.yaml`: lines 2 and 9. Line 9: platform and SRE.
5. `docs/README.md`: lines 2 and 12. Line 12: `@example-org/docs`.
6. `docs/runbooks/escalation.md`: line 2 only, because `docs/*` does not match nested files. `@example-org/platform`.
7. `Docs/guide.md`: line 2 only. Paths are case sensitive, so `docs/*` does not match. Platform.
8. `.github/workflows/ci.yaml`: lines 2, 9 and 15. Line 15: `@example-org/repo-admins`. This is why the `/.github/` line is last: one line higher and `*.yaml` would hand workflow files to other teams.
9. `README.md`: line 2. Platform.
10. Replace line 12 by two lines, in this order, and keep them above `/.github/`:

    ```text
    /docs/              @example-org/docs
    /docs/runbooks/     @example-org/on-call
    ```

    The directory form covers the whole subtree. The more specific line must come later. Both must come after `*.yaml` if YAML files under `docs/` should also follow them.
11. Every Python file in the repository now ends at `*.py`. The routing team loses `router/classify.py`, routing and on-call lose `router/priority.py`, and the platform team loses the remaining Python files such as `tests/test_classify.py`. A Python file under `.github/` would leave the repository admins as well. Nobody "also sees" anything: the last match replaces the earlier owners.
12. With `/.github/` at the top, later lines win. `.github/workflows/ci.yaml` matches `/.github/`, `*` and `*.yaml`; the last is `*.yaml`: platform and SRE. `.github/CODEOWNERS` falls to `*`: platform. The repository admins own nothing any more, and the file that names the reviewers is no longer protected by them.
