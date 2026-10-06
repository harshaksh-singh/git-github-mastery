# Model solution of capstone stage 7 (a shared branch was rebased and force-pushed, and the
# pull request is broken), in the eleven steps of Chapter 30, section 30.16. Sourced by the
# replay script and by capstone/setup.sh --stage N.
cd "$LAB_DIR" || exit 97
cap_as you
B=feature/vip-escalation
pr=$("$LAB_DIR/pr" list | sed -n 's/^#\([0-9]*\) .*feature\/vip-escalation.*/\1/p')

csnip 01-state
run 'cd you'
run 'git status -sb'
run 'git fetch'
run 'git status -sb'
run "../pr view $pr"

csnip 02-graph
run "git log --oneline --graph $B origin/$B --not origin/main~1"

csnip 03-refs
run "git for-each-ref --format='%(refname:short) %(objectname:short) %(upstream:track)' refs/heads/$B refs/remotes/origin/$B refs/remotes/origin/main"
run "git ls-remote origin $B"

csnip 04-reflog-mine
run "git reflog show origin/$B"
run "git reflog show $B"

csnip 05-reflog-teammates
note 'My clone saw a fast-forward. The other two clones saw more:'
run "git -C ../nandini reflog show origin/$B"
run "git -C ../nandini reflog show $B"
run "git -C ../kabir reflog show origin/$B"
run "git -C ../kabir reflog show $B"

csnip 06-old-state
bad=$(git rev-parse --short "origin/$B")
p3=$(git rev-parse --short "origin/$B@{1}")
p2=$(git rev-parse --short "$p3~1")
n1=$(git rev-parse --short "origin/$B^1")
new=$(git rev-parse --short "origin/$B^2")
mine=$(git rev-parse --short "$B")
run "git show --no-patch --format='%h parents: %p' origin/$B"
note 'The shared tip before the rebase, the rebased tip, the review fix, my unpushed tip:'
run "git log --no-walk --format='%h %an: %s' $p3 $new $n1 $mine"

csnip 07-what-changed
note 'Are the rebased commits the same changes as the old ones?'
run "git range-diff origin/main~1..$p2 origin/main..$new"
note 'Did the forced push carry the commit I had pushed before it?'
run_rc "git merge-base --is-ancestor $p3 $new"
run "git log --oneline $new..$p3"
run_rc 'git -C ../kabir config get push.useForceIfIncludes'
run 'git -C ../nandini config get pull.rebase'

csnip 08-preserve
run "git branch rescue/server-state origin/$B"
run "git branch rescue/my-work $B"

csnip 09-rebuild
note 'Keep the rebased series. Replay what lies after the old shared history: my two commits,'
note 'then the review fix.'
run "git rebase --onto $new $p2"
run "git cherry-pick $n1"
run "git log --oneline --graph origin/main~1..$B"

csnip 10-check-result
run "git range-diff $p2..rescue/my-work $new..$B~1"
run "git range-diff $n1~1..$n1 $B~1..$B"
note 'Content: the new tip must equal what a merge of the server state and my work would give.'
run 'git merge-tree --write-tree rescue/server-state rescue/my-work'
run "git rev-parse '$B^{tree}'"
run 'bash scripts/test.sh'

csnip 11-publish
run "git push --force-with-lease=$B:$bad origin $B"
run "../pr view $pr"

csnip 12-teammates
note 'Nandini stands on the merge. A pull would merge again. Is anything of hers not upstream?'
cap_as nandini
run 'cd ../nandini'
run 'git fetch'
run 'git status -sb'
note 'A first idea: list her commits that have no patch-equivalent upstream.'
run "git log --oneline --no-merges --cherry-pick --right-only origin/$B...$B"
note 'Those are the old copies of two commits that range-diff paired with upstream commits.'
note 'A sharper test: if merging her branch into the new one changes nothing, nothing is missing.'
run "git merge-tree --write-tree origin/$B $B"
run "git rev-parse 'origin/$B^{tree}'"
run "git reset --keep origin/$B"
note 'Kabir stands on the rebased tip, an ancestor of the new one.'
cap_as kabir
run 'cd ../kabir'
run 'git pull --ff-only'

csnip 13-prevent
run 'git config set push.useForceIfIncludes true'
run 'git -C ../nandini config set pull.ff only'
run 'git -C ../nandini config unset pull.rebase'
cap_as you
run 'cd ../you'
run 'git config set pull.ff only'
run 'git branch -D rescue/server-state rescue/my-work'
run 'git status -sb'
run 'cd ..'
cshow_check
