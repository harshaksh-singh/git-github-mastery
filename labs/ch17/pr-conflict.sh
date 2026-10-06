#!/usr/bin/env bash
# A pull request that conflicts with its base, and the two ways to repair it: merge the base
# branch into the head branch, or rebase the head branch onto the base. Compares what each
# does to the commit list, to commit IDs and to the push. Chapter 17, section 17.7.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch17 pr-conflict
scenario_conflict
cd "$LAB_DIR" || exit 1
mkdir rebase-copy && cp -R server ravi rebase-copy/
cd ravi/ticket-router || exit 1

snip 01-conflict
note 'Ravi. His pull request fix/threshold -> main, and the test merge:'
run 'git log --oneline origin/main..fix/threshold'
run_rc 'git merge-tree --write-tree --name-only origin/main fix/threshold'

snip 02-merge-base-in
note 'Repair 1: merge the base branch into the head branch.'
run_rc 'git merge origin/main'
run 'git diff'
run "printf 'model: router-small-v1\nconfidence_threshold: 0.65\nfallback_queue: general\n' > config/routing.yaml"
run 'git add config/routing.yaml'
run 'git commit -q -m "Merge main into fix/threshold"'
run 'git push'

snip 03-after-merge
run 'git log --oneline --graph -5'
run 'git log --oneline origin/main..fix/threshold'
run_rc 'git merge-tree --write-tree origin/main fix/threshold'

snip 04-rebase
note 'Repair 2, in a copy of the clone: rebase the head branch onto the base.'
run 'cd ../../rebase-copy/ravi/ticket-router'
run_rc 'git rebase origin/main'
run "printf 'model: router-small-v1\nconfidence_threshold: 0.65\nfallback_queue: general\n' > config/routing.yaml"
run 'git add config/routing.yaml'
run 'git rebase --continue'

snip 05-after-rebase
run 'git log --oneline --graph -5'
run 'git log --oneline origin/main..fix/threshold'
run_rc 'git push'
run 'git push --force-with-lease'

snip 06-same-diff
note 'Both repairs give reviewers the same three-dot diff:'
run 'git diff origin/main...fix/threshold'
run 'diff <(git -C ../../../ravi/ticket-router diff origin/main...fix/threshold) <(git diff origin/main...fix/threshold) && echo identical'

lab_end
