#!/usr/bin/env bash
# Chapter 29, sections 29.2, 29.3 and 29.9: worked case 1 through the whole root-cause framework.
# Symptom: "git push says Everything up-to-date, and the pull request does not show my two new
# commits." State: a rebase stopped at a conflict days ago and was never continued; the new
# commits were made on the detached HEAD of that rebase.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch29 case-unfinished-rebase
fx_case_rebase
cd scoring-api || exit 1

snip 01-symptom
run 'git push origin feature/latency-budget'

snip 02-status
run 'git status'

snip 03-branch
run 'git branch -vv'

snip 04-remote
run 'git remote -v'

snip 05-log
run 'git log --graph --decorate --oneline --all'

snip 06-reflog
run 'git reflog'

snip 07-rev-parse
run 'git rev-parse HEAD feature/latency-budget origin/feature/latency-budget'
run 'git rev-parse --abbrev-ref HEAD'
run_rc 'git symbolic-ref HEAD'

snip 08-show
run 'git show --stat HEAD'

snip 09-diff
run 'git diff'
run 'git diff --cached'

snip 10-config
run 'git config list --show-origin --show-scope'

snip 11-ls-files
run 'git ls-files'

snip 12-state-files
run 'cat .git/HEAD'
run 'ls .git/rebase-merge'
run 'cat .git/rebase-merge/head-name'
run 'cat .git/rebase-merge/orig-head'
run 'cat .git/rebase-merge/onto'
run 'cat .git/rebase-merge/done'
run 'cat .git/rebase-merge/git-rebase-todo'

snip 13-test
note 'H2: which commits does HEAD have that the branch does not?'
run 'git log --oneline feature/latency-budget..HEAD'
note 'H4: what does the server hold?'
run 'git ls-remote origin'
note 'Where is each new commit reachable from?'
run 'git branch -a --contains HEAD'

snip 14-preserve
run 'git branch rescue/latency-wip HEAD'
run 'git log --oneline -4 rescue/latency-wip'

snip 15-abort
run 'git rebase --abort'
run 'git status'
run 'git log --oneline -3'

snip 16-pick
run 'git cherry-pick rescue/latency-wip~1 rescue/latency-wip'
run 'git log --oneline origin/feature/latency-budget..HEAD'

snip 17-push
run 'git push --dry-run origin feature/latency-budget'
run 'git push origin feature/latency-budget'

snip 18-verify
run 'git status'
run 'git rev-parse HEAD origin/feature/latency-budget'
run 'git ls-remote origin feature/latency-budget'
run 'git cherry -v HEAD rescue/latency-wip'
run 'ls .git | grep -c rebase'

lab_end
