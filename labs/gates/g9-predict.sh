#!/usr/bin/env bash
# Gate 9 (Production debugging), prediction part. The pN-setup snippets are printed in the gate
# file, the pN-answer snippets only in the answer key.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin gates g9-predict

# ---- P1: "reset --hard" in the middle of a cherry-pick sequence
snip p1-setup
run 'git init -q hotfixes'
run 'cd hotfixes'
run "printf 'limit: 10\n' > limits.yaml && git add . && git commit -q -m 'Add limits'"
run 'git switch -q -c fixes'
run "printf 'retries: 3\n' > retry.yaml && git add . && git commit -q -m 'Fix A: add retries'"
run "printf 'limit: 20\n' > limits.yaml && git commit -q -am 'Fix B: raise the limit'"
run "printf 'timeout: 5\n' > timeout.yaml && git add . && git commit -q -m 'Fix C: add a timeout'"
run 'git switch -q main'
run "printf 'limit: 15\n' > limits.yaml && git commit -q -am 'Tune the limit'"
run 'git cherry-pick main..fixes > /dev/null 2>&1; echo "exit status: $?"'
run 'git status --short'
note 'The developer wants to get out of the conflict and types:'
run 'git reset -q --hard'
snip p1-answer-a
run 'git status'
run 'git log --format=%s -3'
run 'ls .git | grep -E "CHERRY|sequencer" || echo "(none of these exist)"'
snip p1-setup-b
note 'Seeing "cherry-pick in progress", the developer continues:'
run 'git cherry-pick --continue > /dev/null 2>&1; echo "exit status: $?"'
snip p1-answer-b
run 'git log --format=%s -4'
run 'cat limits.yaml'
run 'git status -sb'
cd "$LAB_DIR"

# ---- P2: after a merge was reverted
snip p2-setup
run 'git init -q billing'
run 'cd billing'
run "printf 'a\n' > core.txt && git add . && git commit -q -m 'Add core'"
run 'git switch -q -c feature/invoices'
run "printf 'i\n' > invoices.txt && git add . && git commit -q -m 'Add invoices'"
run 'git switch -q main'
run 'git merge -q --no-ff -m "Merge feature/invoices" feature/invoices'
run "printf 'a\nb\n' > core.txt && git commit -q -am 'Extend core'"
run 'git revert -m 1 --no-edit HEAD~1 > /dev/null'
snip p2-answer
run 'git ls-files'
run_rc 'git merge-base --is-ancestor feature/invoices main'
run 'git branch --merged main'
run 'git merge feature/invoices'
run 'git ls-files'
cd "$LAB_DIR"

# ---- P3: a lease, after a fetch
mk() {
  mkdir "$1" && cd "$1" || exit 1
  quiet 'git init --bare server.git'
  quiet 'git clone server.git you && git -C you remote set-url origin ../server.git'
  cd you || exit 1
  quiet 'git commit --allow-empty -m "Add service"'
  quiet 'git push -u origin main'
  quiet 'git switch -c feature/cache'
  quiet 'git commit --allow-empty -m "Add cache"'
  quiet 'git push -u origin feature/cache'
  cd ..
  quiet 'git clone server.git asha && git -C asha remote set-url origin ../server.git'
  cd you || exit 1
}
mk p3
snip p3-setup
note 'you/ and asha/ are clones of one server. feature/cache has one commit, "Add cache", pushed by you.'
as asha
run 'git -C ../asha switch -q feature/cache'
run 'git -C ../asha commit -q --allow-empty -m "Asha: add cache metrics"'
run 'git -C ../asha push -q origin feature/cache'
as you
run 'git commit -q --amend --allow-empty -m "Add cache with eviction"'
run 'git fetch -q'
run 'git status -sb'
snip p3-answer-a
run_rc 'git push --force-with-lease --force-if-includes origin feature/cache'
run 'git -C ../server.git log --format=%s feature/cache'
snip p3-setup-b
run 'git push --force-with-lease origin feature/cache > push.log 2>&1; echo "exit status: $?" >> push.log'
snip p3-answer-b
run 'tail -1 push.log'
run 'git -C ../server.git log --format=%s feature/cache'
run "git log -g --format='%h %gs' origin/feature/cache"
cd "$LAB_DIR"

# ---- P4: a release tag that was moved on the server
mkdir p4 && cd p4 || exit 1
quiet 'git init --bare server.git'
quiet 'git clone server.git ravi && git -C ravi remote set-url origin ../server.git'
cd ravi || exit 1
quiet 'git commit --allow-empty -m "Add service"'
quiet 'git commit --allow-empty -m "Release candidate"'
quiet 'git tag -a v1.4.0 -m "1.4.0"'
quiet 'git push -u origin main v1.4.0'
cd ..
quiet 'git clone server.git you && git -C you remote set-url origin ../server.git'
cd you || exit 1
snip p4-setup
note 'you/ cloned the server when v1.4.0 named "Release candidate". Then, in ravi/:'
as ravi
run 'git -C ../ravi commit -q --allow-empty -m "Late fix"'
run 'git -C ../ravi tag -f -a v1.4.0 -m "1.4.0" > /dev/null'
run 'git -C ../ravi push -q --force origin main v1.4.0'
as you
snip p4-answer
run 'git fetch'
run "git log -1 --format=%s 'v1.4.0^{commit}'"
run_rc 'git fetch --tags'
run "git log -1 --format=%s 'v1.4.0^{commit}'"
run "git ls-remote origin 'refs/tags/v1.4.0^{}' | cut -f1 | xargs git log -1 --format=%s"
lab_end
