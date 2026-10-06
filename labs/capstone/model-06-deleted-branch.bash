# Model solution of capstone stage 6 (a branch that a teammate needs was deleted on the
# server). Sourced by the replay script and by capstone/setup.sh --stage N.
cd "$LAB_DIR" || exit 97
cap_as you
B=feature/multilingual-intents
pr=$("$LAB_DIR/pr" list --all | sed -n 's/^#\([0-9]*\) *closed .*feature\/multilingual-intents.*/\1/p' | tail -n 1)

csnip 01-observe
run 'cd you'
run "git ls-remote origin 'refs/heads/feature/*'"
run '../pr list --all | tail -n 3'
run "../pr view $pr"

csnip 02-what-the-clones-have
note 'My clone has a remote-tracking branch from my last fetch. I do not fetch with --prune'
note 'now: that would delete the one copy of the name I have.'
run "git log --oneline origin/main..origin/$B"
note 'Nandini saw three commits in the pull request. This is two.'
run "git -C ../tanvi branch -r --list 'origin/feature/*'"
run "git -C ../nandini branch -r --list 'origin/feature/*'"

csnip 03-cause
run 'cat ../evidence/stage-06/cleanup-merged-branches.sh'
run 'cat ../evidence/stage-06/cleanup-output.txt'
stale=$(sed -n 's/.*multilingual-intents (\([0-9a-f]*\)).*/\1/p' ../evidence/stage-06/cleanup-output.txt)

csnip 04-test-the-cause
note 'Her clone thought the branch ended at the commit in the output. Is that commit merged?'
run "git log --oneline -1 $stale"
run_rc "git merge-base --is-ancestor $stale origin/main"
run "git log --oneline --merges -1 --ancestry-path $stale..origin/main"
note 'And the branch as I last saw it?'
run_rc "git merge-base --is-ancestor origin/$B origin/main"

csnip 05-find-the-tip
run "git ls-remote origin 'refs/pull/$pr/*'"
run "git fetch origin refs/pull/$pr/head"
run 'git log --oneline origin/main..FETCH_HEAD'
run "git log --oneline origin/$B..FETCH_HEAD"

csnip 06-restore
tipid=$(git rev-parse --short FETCH_HEAD)
run "git push origin $tipid:refs/heads/$B"
run "../pr reopen $pr"
run "../pr view $pr"

csnip 07-verify
run 'git fetch'
run "git log --oneline origin/main..origin/$B"
run "git switch --quiet --detach origin/$B"
run 'bash scripts/test.sh'
run 'git switch --quiet main'

csnip 08-prevent
note "The script, repaired in Tanvi's clone: prune first, so that the list is the server's."
cap_as tanvi
run 'cd ../tanvi'
run 'git branch -r --merged origin/main'
run 'git fetch --prune'
run 'git branch -r --merged origin/main'
cap_as you
run 'cd ..'
cshow_check
