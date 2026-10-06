#!/usr/bin/env bash
# Final test, section 7 (Recovery): prediction items P1 and P2, diagram item G1 and
# interpretation items I1 and I2.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin final s07

# ---- P1: a deleted branch and its reflog
snip p1-setup
run 'git init -q ocrqueue'
run 'cd ocrqueue'
run 'git commit -q --allow-empty -m "Add the queue"'
run 'git switch -q -c spike/priority'
run 'git commit -q --allow-empty -m "Try a priority heap"'
run 'git switch -q main'
run 'git branch -q -D spike/priority'
snip p1-answer
run_rc 'git reflog show spike/priority'
run 'git reflog'
run "git log -1 --format=%s 'HEAD@{1}'"
run 'git branch --contains "HEAD@{1}"'
cd "$LAB_DIR"

# ---- P2: what survives expiry and pruning
snip p2-setup
run 'git init -q ckptstore'
run 'cd ckptstore'
run "printf 'lr: 0.1\n' > run.yaml"
run 'git add . && git commit -q -m "Add the baseline run"'
run "printf 'lr: 0.01\n' > run.yaml"
run 'git commit -q -a -m "Experiment X"'
run 'x=$(git rev-parse HEAD)'
run 'git reset -q --hard HEAD~1'
run "printf 'lr: 0.5\n' > run.yaml"
run 'git commit -q -a -m "Experiment Y"'
run 'y=$(git rev-parse HEAD)'
run 'git tag keep/y'
run 'git reset -q --hard HEAD~1'
run "printf 'lr: 0.2\n' > run.yaml"
run 'git stash push -q -m "older idea"'
run 'z1=$(git rev-parse stash@{0})'
run "printf 'lr: 0.3\n' > run.yaml"
run 'git stash push -q -m "newer idea"'
run 'z2=$(git rev-parse stash@{0})'
run 'git reflog expire --expire=now --all'
run 'git gc --quiet --prune=now'
snip p2-answer
run_rc 'git cat-file -t $x'
run_rc 'git cat-file -t $y'
run_rc 'git cat-file -t $z1'
run_rc 'git cat-file -t $z2'
run 'git stash list'
run 'git log --format=%s -1 refs/stash'
cd "$LAB_DIR"

# ---- G1: read a branch reflog
quiet 'git init -q dataloader'
cd dataloader || exit 1
quiet 'git commit -q --allow-empty -m "Add the loader"'
quiet 'git commit -q --allow-empty -m "Add the tokenizer"'
quiet 'git commit -q --allow-empty -m "Add batching"'
quiet 'git reset -q --hard HEAD~2'
quiet 'git commit -q --allow-empty -m "Add the streaming loader"'
quiet 'git switch -q -c feature/shuffle'
quiet 'git commit -q --allow-empty -m "Add a shuffle buffer"'
quiet 'git commit -q --allow-empty -m "Seed the shuffle buffer"'
quiet 'git switch -q main'
quiet 'git merge -q feature/shuffle'
quiet 'git commit -q --allow-empty --amend -m "Seed the shuffle buffer from the run configuration"'
snip g1-reflog
run 'git reflog show main'
snip g1-answer
run "git log -1 --format=%s 'main@{4}'"
run "git log --format=%s 'main@{3}..main@{4}'"
run "git log -1 --format=%s 'main@{2}'"
run "git log --format=%s 'main@{2}..main@{1}'"
run "git merge-base --is-ancestor 'main@{1}' main; echo \"exit status \$?\""
run 'git log --graph --oneline main "main@{1}" "main@{4}"'
cd "$LAB_DIR"

# ---- I1: a remote-tracking reflog after somebody's forced push
quiet 'git init -q --bare server.git'
quiet 'git clone -q server.git you'
quiet 'git -C you remote set-url origin ../server.git'
cd you || exit 1
printf 'daily: 1000\n' > quotas.yaml
quiet 'git add . && git commit -q -m "Add quotas" && git push -q -u origin main'
quiet 'git switch -q -c feature/quotas'
printf 'daily: 1000\nburst: 50\n' > quotas.yaml
quiet 'git commit -q -a -m "Add a burst quota"'
printf 'daily: 1000\nburst: 50\nper_key: true\n' > quotas.yaml
quiet 'git commit -q -a -m "Count quotas per API key"'
quiet 'git push -q -u origin feature/quotas'
cd "$LAB_DIR" || exit 1
quiet 'git clone -q server.git asha'
quiet 'git -C asha remote set-url origin ../server.git'
cd asha || exit 1
as asha
quiet 'git switch -q feature/quotas'
quiet 'git reset -q --hard HEAD~1'
printf 'daily: 1000\nburst: 50\nwindow_s: 60\n' > quotas.yaml
quiet 'git commit -q -a -m "Add a quota window"'
quiet 'git push -q --force origin feature/quotas'
cd "$LAB_DIR/you" || exit 1
as you
snip i1-transcript
run 'git fetch'
run 'git status -sb'
run 'git reflog show origin/feature/quotas'
run "git log --oneline --left-right 'origin/feature/quotas@{1}...origin/feature/quotas'"
cd "$LAB_DIR"

# ---- I2: unreachable and dangling
quiet 'git init -q promptpack'
cd promptpack || exit 1
printf 'system: be brief\n' > prompt.yaml
quiet 'git add . && git commit -q -m "Add the system prompt"'
quiet 'git switch -q -c feature/few-shot'
printf 'examples: 2\n' > shots.yaml
quiet 'git add . && git commit -q -m "Add two examples"'
printf 'examples: 4\n' > shots.yaml
quiet 'git commit -q -a -m "Add two more examples"'
quiet 'git switch -q main'
printf 'system: be brief and cite sources\n' > prompt.yaml
quiet 'git commit -q -a -m "Ask for citations"'
quiet 'git switch -q feature/few-shot'
quiet 'git rebase -q main'
snip i2-transcript
run 'git fsck'
run 'git fsck --no-reflogs --unreachable'
run 'git fsck --no-reflogs --dangling'
run 'git fsck --no-reflogs --dangling | cut -d" " -f3 | xargs git log -1 --format=%s'
lab_end
