# Model solution of capstone stage 5 (an accidental "git reset --hard" on work that was never
# pushed). Sourced by the replay script and by capstone/setup.sh --stage N.
cd "$LAB_DIR" || exit 97
cap_as tanvi
B=feature/routing-metrics

csnip 01-observe
note "At Tanvi's machine, with her. Nothing is changed until the evidence is read."
run 'cd tanvi'
run 'git status -sb'
run 'git branch -vv'
run 'git log --oneline -3'

csnip 02-reflog
run 'git reflog -7'
run 'git reflog show main'
note 'She suspects the fetch or a rebase. Does the HEAD reflog record a rebase at all?'
run_rc 'git reflog | grep -c rebase'

csnip 03-anchor
run "git branch rescue/before-reset 'main@{1}'"
run 'git log --oneline origin/main..rescue/before-reset'
run 'git diff --stat origin/main...rescue/before-reset'

csnip 04-staged
run 'git fsck --lost-found'
blob=$(ls .git/lost-found/other | head -n 1)
run 'ls .git/lost-found/other'
run "git cat-file -p ${blob:0:7}"
note 'For comparison, fsck without --lost-found:'
run 'git fsck'

csnip 05-recover
note 'The commits belong on the branch she meant to use, not on main.'
run 'git cherry-pick origin/main..rescue/before-reset'
run 'mkdir -p deploy'
run "git cat-file -p ${blob:0:7} > deploy/alerts.yaml"
run 'git add -f deploy/alerts.yaml'
run 'git status -sb'

csnip 06-verify
run 'git range-diff origin/main rescue/before-reset HEAD'
run 'bash scripts/test.sh'
run 'git log --oneline --graph -5'

csnip 07-not-recoverable
note 'Two things were never given to Git: an edit to README.md that was not staged, and'
note 'the notes file that was never added. Git has no object for either.'
run_rc 'ls notes'
run 'git diff --stat HEAD -- README.md'
run "git log --all --oneline -S'histogram of blended scores'"

csnip 08-publish
run "git push -u origin $B"
run 'git branch -vv'
run 'git branch -D rescue/before-reset'
cap_as you
run 'cd ..'
cshow_check
