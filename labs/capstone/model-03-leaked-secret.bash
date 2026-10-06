# Model solution of capstone stage 3 (a dummy secret in pushed history). Sourced by the replay
# script and by capstone/setup.sh --stage N. Step 1, revoking the credential, is not a Git
# command and happens before anything below.
cd "$LAB_DIR" || exit 97
cap_as you
A=feature/embedding-client
T=feature/embedding-latency-log

csnip 01-find
run 'cd you'
run 'git fetch'
run 'git log --all --oneline -- deploy/staging.env'
add=$(git log --all --diff-filter=A --format=%h -- deploy/staging.env)
rm=$(git log --all --diff-filter=D --format=%h -- deploy/staging.env)
run "git show $add:deploy/staging.env"

csnip 02-scope
note 'Which refs in my clone reach the commit that added the file?'
run "git branch -r --contains $add"
run "git tag --contains $add"
note 'The server has refs that a clone does not fetch. As its administrator, ask it directly:'
run "git -C ../server.git for-each-ref --contains $add --format='%(refname)'"
note 'Is it in main or in a release?'
run_rc "git merge-base --is-ancestor $add origin/main"
note 'Since when has the server had it? The pushing clone recorded the time:'
run "git -C ../kabir reflog show --date=iso origin/$A"

csnip 03-not-clean
note 'The tip has no such file. The history under the tip has, and a squash merge of the pull'
note 'request would not change that: the pull request ref keeps the original commits.'
run_rc "git cat-file -e origin/$A:deploy/staging.env"
run "git log --oneline origin/main..refs/remotes/origin/$A"
run 'git ls-remote origin refs/pull/16/head'

csnip 04-rewrite
cap_as kabir
run 'cd ../kabir'
run 'git status -sb'
run_todo "s/^pick $add /edit $add /; s/^pick $rm /drop $rm /" 'git rebase -i main'

csnip 05-amend
run 'git rm --cached deploy/staging.env'
run "printf 'deploy/*.env\n' >> .gitignore"
run 'git add .gitignore'
run 'git commit --amend --no-edit'
run 'git rebase --continue'

csnip 06-check-rewrite
run "git log --oneline main..$A"
run "git log --oneline $A -- deploy/staging.env"
run "git range-diff '$A@{u}'...$A"
run 'git status -sb --ignored'

csnip 07-publish
old2=$(git rev-parse --short "origin/$A~2")
run 'git push --force-with-lease --force-if-includes'
new2=$(git log --format=%h -1 --grep='^Cache embeddings by message hash$' "$A")

csnip 08-dependent-branch
cap_as tanvi
run 'cd ../tanvi'
run 'git fetch'
run "git log --oneline --graph origin/$A $T -6"
run "git rebase --onto $new2 $old2 $T"
run "git log --oneline main..$T"
run 'git push --force-with-lease --force-if-includes'

csnip 09-tag
note 'A tag is a ref too. It still names the old commit, and a tag does not move on its own.'
run 'git rev-parse --short staging/2026-09-16'
run "git tag -f staging/2026-09-16 $new2"
run "git push --force-with-lease=refs/tags/staging/2026-09-16:$old2 origin refs/tags/staging/2026-09-16"
run 'git switch --quiet main'

csnip 10-server-still-has-it
cap_as you
run 'cd ../you'
run "git -C ../server.git for-each-ref --contains $add --format='%(refname)'"
note 'No ref on the server reaches the old commits now. The objects are still there:'
run "git -C ../server.git cat-file -t $add"
run "git -C ../server.git show $add:deploy/staging.env | grep -c TOKEN"

csnip 11-server-prune
note 'You are the administrator of this server. On GitHub this step is a request to GitHub Support.'
run 'git -C ../server.git gc --prune=now'
run_rc "git -C ../server.git cat-file -t $add"

csnip 12-clones
note 'Every clone that fetched the branch or the tag still has the old commits: under'
note 'remote-tracking refs and tags until it fetches, and in its reflogs after that.'
run 'git -C ../nandini tag --contains '"$add"
run 'for c in you nandini kabir tanvi; do git -C ../$c fetch --quiet --prune --force --tags; done'
run "git -C ../nandini for-each-ref --contains $add"
run "git -C ../nandini cat-file -t $add"
run 'for c in you nandini kabir tanvi; do git -C ../$c reflog expire --expire=now --all && git -C ../$c gc --quiet --prune=now; done'
run_rc "git -C ../nandini cat-file -t $add"

csnip 13-verify
run 'git log --all --oneline -- deploy/staging.env'
run "git log --oneline --graph origin/main~1..origin/$A origin/$T"
run '../pr view 16'
run 'git -C ../kabir status -sb --ignored'
run 'cd ..'
cshow_check
