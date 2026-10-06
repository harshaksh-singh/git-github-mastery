# Consistency items for the final editorial pass

Found while compiling the reference set and the interview bank. Each needs a decision from primary sources, then the same wording everywhere.

1. `git branch -d` after a squash or rebase merge: Chapters 7 (7.x, lines near 1372, 1441, 1566) and 8 (near 2053) state the refusal unconditionally. Real behavior (shown in Chapters 15, 17, 27): with an upstream that still contains the branch it deletes with a warning; it refuses when there is no upstream or after the remote-tracking ref is pruned. Make 7 and 8 conditional.
2. File-size unit: 15.15 and 22.11 say 100 MiB; 18.12 says "100 MB". Use MiB as GitHub's docs do.
3. Audit log and Git events: 15.19, 13.15 and 21B.8 differ (seven-day figure only in 13.15; "through the API" versus "need an export"). Reconcile with the Phase 0 report section 13/14 wording and its sources.
4. SSH key lifetime: 16.6 table says "until deleted"; 16.8 says GitHub deletes SSH keys unused for a year. Reconcile with the docs.
5. `workflow_dispatch`: 20B.11 corrected on 5 Oct. Align the interview-bank answer for the Chapter 20A question 5 (search "workflow_dispatch" in interview/cto-question-bank-answers.md) and check 20A.18's "read the workflow file at that ref".
6. 20A.4 events table omits `pull_request_target`, which 18.8 and 21A.5 rely on: add a row or a pointer to 21A.
7. 21A.5 quotes the insecure documentation example with `actions/checkout@v6` while the course pins v7.0.1: add a sentence that the quote is the documentation's own example.
8. 14B.5 says "the twenty below"; the table has 19 rows: fix the count.
9. Risk-label disagreements between chapters: see reference/command-safety.md section 12. Decide one label per command and apply it in the chapters (or state in each chapter why the context changes the label).
10. `gh` sheet labels to confirm: `gh ssh-key add`, `gh repo set-default`, `gh api graphql` read-only query.
11. 14C.9 `prepare-commit-msg` sentence corrected on 5 Oct (it can stop a commit).
12. START-HERE.md is stale: rewrite at the end.
13. Chapter 5, section 5.12 says a merge is "refused" over a skip-worktree edit. Two exercise authors saw a same-size, same-second edit silently overwritten once (not reproducible on demand; see solutions/exercises-m16-m18.md 17.8 and exercises/gen/m02-invisible-edit). Add a caution in 5.12 that the protection depends on the cached stat data and is not a guarantee.
