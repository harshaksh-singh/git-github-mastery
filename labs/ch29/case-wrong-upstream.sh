#!/usr/bin/env bash
# Chapter 29, sections 29.4 and 29.5: worked case 2 through the root-cause framework, and the
# extended toolbox on the same repository. Symptom: "git push is rejected; I pull, Git says
# Already up to date, and the push is rejected again." State: the branch was created from
# origin/main, so its upstream is origin/main, while the push goes to a branch of the same name
# that a teammate pushed first.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch29 case-wrong-upstream
fx_case_upstream
cd embed-jobs || exit 1

snip 01-symptom
run_rc 'git push origin feature/batch-size'
run 'git pull'
run_rc 'git push origin feature/batch-size'

snip 02-evidence
run 'git status'
run 'git branch -vv'
run 'git log --graph --decorate --oneline --all'

snip 03-evidence-config
run 'git config list --show-origin --show-scope | grep -E "(branch|remote)[.]"'
run 'git reflog -4'

snip 04-toolbox-refs
run 'git status -sb'
run "git for-each-ref --format='%(refname) %(objectname:short) %(upstream:short) %(upstream:track)'"
run 'git rev-parse --abbrev-ref @{upstream}'
run_rc 'git rev-parse --abbrev-ref @{push}'

snip 05-toolbox-graph
run 'git merge-base HEAD origin/feature/batch-size'
run 'git rev-list --left-right --count HEAD...origin/feature/batch-size'
run 'git log --oneline --left-right HEAD...origin/feature/batch-size'
run 'git branch -a --contains origin/feature/batch-size'

snip 06-toolbox-remote
run 'git ls-remote origin'
run 'git reflog show --date=iso origin/feature/batch-size'
run 'git remote show origin'

snip 07-toolbox-objects
run 'git cat-file -t origin/feature/batch-size'
run 'git cat-file -p origin/feature/batch-size'
run 'git ls-files -s'
run 'git fsck'

snip 08-test
note 'H1: the server branch has a commit that the local branch lacks.'
run 'git log --oneline HEAD..origin/feature/batch-size'
note 'H1: and git pull integrates another branch.'
run 'git config get branch.feature/batch-size.merge'
note 'H3: was the server branch rewritten? Its remote-tracking reflog has one entry, a first fetch.'
run 'git reflog show origin/feature/batch-size'
note 'Would the two lines of work conflict? A test merge that touches nothing:'
run_rc 'git merge-tree --write-tree --name-only HEAD origin/feature/batch-size'

snip 09-fix
run 'git branch backup/batch-size-before-rebase'
run 'git branch --set-upstream-to=origin/feature/batch-size'
run 'git status -sb'
run 'git rebase'
run 'git log --graph --oneline -4'

snip 10-push
run 'git push --dry-run'
run 'git push'

snip 11-verify
run 'git status'
run 'git branch -vv'
run 'git rev-parse HEAD @{upstream}'
run 'git ls-remote origin feature/batch-size'
run 'git range-diff origin/main backup/batch-size-before-rebase HEAD'
run 'git pull'

snip 12-prevent
run 'git branch -D backup/batch-size-before-rebase'
note 'A new branch from origin/main that does not take origin/main as its upstream:'
run 'git switch -c feature/shard-output --no-track origin/main'
run 'git branch -vv'
run_rc 'git push'

lab_end
