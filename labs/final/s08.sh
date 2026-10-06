#!/usr/bin/env bash
# Final test, section 8 (Remote workflows): prediction items P1 and P2, diagram item G1 and
# interpretation items I1 and I2.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin final s08

mk_pair() {   # mk_pair <dir>: a bare server and the clones you/ and asha/ under <dir>
  mkdir "$1" && cd "$1" || exit 1
  quiet 'git init -q --bare server.git'
  quiet 'git clone -q server.git you && git -C you remote set-url origin ../server.git'
  cd you || exit 1
  quiet 'git commit -q --allow-empty -m "Add the service" && git push -q -u origin main'
  cd .. || exit 1
  quiet 'git clone -q server.git asha && git -C asha remote set-url origin ../server.git'
  quiet "git -C asha config set user.name 'Asha Rao' && git -C asha config set user.email asha@example.com"
}

# ---- P1: a lease with an explicit value, and --force-if-includes
mk_pair p1
cd you || exit 1
quiet 'git switch -q -c feature/cache'
printf 'ttl: 60\n' > cache.yaml
quiet 'git add . && git commit -q -m "Add a response cache" && git push -q -u origin feature/cache'
as asha
quiet 'git -C ../asha fetch -q && git -C ../asha switch -q feature/cache'
quiet 'git -C ../asha commit -q --allow-empty -m "Add cache metrics"'
quiet 'git -C ../asha push -q'
as you
snip p1-setup
note 'you/ and asha/ are clones of one server. You pushed "Add a response cache" to feature/cache.'
note 'Then Asha pushed "Add cache metrics" on top of it. You have not fetched since your push.'
run 'seen=$(git rev-parse origin/feature/cache)'
run "printf 'ttl: 120\n' > cache.yaml"
run 'git commit -q -a --amend --no-edit'
note 'Your editor fetches in the background:'
run 'git fetch -q'
snip p1-answer
run_rc 'git push --force-with-lease=feature/cache:$seen origin feature/cache'
run_rc 'git push --force-with-lease --force-if-includes origin feature/cache'
run 'git log --oneline -1 origin/feature/cache'
run 'git status -sb'
cd "$LAB_DIR"

# ---- P2: pushing into a repository that has a working tree
snip p2-setup
run 'git init -q kiosk'
run 'git -C kiosk commit -q --allow-empty -m "Add the kiosk page"'
run 'git clone -q kiosk kiosk-dev'
run 'cd kiosk-dev'
run 'git commit -q --allow-empty -m "Add the idle screen"'
snip p2-answer
run_rc 'git push origin main > ../push.log 2>&1'
run 'grep -E "refusing|rejected" ../push.log | sed "s/ *$//"'
run_rc 'git push -q origin main:refs/heads/incoming'
run 'git -C ../kiosk branch -v'
cd "$LAB_DIR"

# ---- G1: three repositories, five refs
mk_pair g1
snip g1-setup
note 'server.git is the server; you/ and asha/ are clones. All three have main at "Add the service".'
run 'git -C you commit -q --allow-empty -m "Y1: add health check"'
run 'git -C you push -q'
run 'git -C asha fetch -q'
as asha
run 'git -C asha commit -q --allow-empty -m "A1: add request log"'
as you
run 'git -C you commit -q --allow-empty -m "Y2: add readiness probe"'
snip g1-answer
run "git -C server.git for-each-ref --format='%(refname) -> %(subject)' refs/heads"
run "git -C you for-each-ref --format='%(refname) -> %(subject)' refs/heads refs/remotes/origin/main"
run "git -C asha for-each-ref --format='%(refname) -> %(subject)' refs/heads refs/remotes/origin/main"
run 'git -C you status -sb'
run 'git -C asha status -sb'
cd "$LAB_DIR"

# ---- I1: two rejections that look alike
mk_pair i1
as asha
quiet 'git -C asha commit -q --allow-empty -m "Add the admin page" && git -C asha push -q'
as you
cd you || exit 1
quiet 'git commit -q --allow-empty -m "Add the status page"'
snip i1-transcript
run_rc 'git push'
run 'git fetch'
run_rc 'git push'
cd "$LAB_DIR"

# ---- I2: the lines of a fetch
mk_pair i2
cd you || exit 1
for b in feature/a feature/c; do
  quiet "git switch -q -c $b main && git commit -q --allow-empty -m 'Work on $b' && git push -q -u origin $b"
done
quiet 'git switch -q main'
cd ../asha || exit 1
as asha
quiet 'git fetch -q'
quiet 'git switch -q feature/a && git commit -q --allow-empty --amend -m "Rework feature/a" && git push -q --force'
quiet 'git push -q origin --delete feature/c'
quiet 'git switch -q -c feature/b main && git commit -q --allow-empty -m "Start feature/b" && git push -q -u origin feature/b'
quiet 'git switch -q main && git commit -q --allow-empty -m "Add the changelog" && git tag -a v2.0 -m "Release 2.0" && git push -q origin main v2.0'
cd ../you || exit 1
as you
snip i2-transcript
run 'git fetch --prune'
run 'git branch -vv'
lab_end
