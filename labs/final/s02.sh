#!/usr/bin/env bash
# Final test, section 2 (Git internals): prediction items P1 to P3, diagram item G1 and
# interpretation items I1 and I2.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin final s02

# ---- P1: two kinds of tag
snip p1-setup
run 'git init -q modelzoo'
run 'cd modelzoo'
run 'git commit -q --allow-empty -m "Add the model registry"'
run 'git tag candidate'
run 'git tag -a v1.0 -m "Release 1.0"'
snip p1-answer
run 'git count-objects | cut -d, -f1'
run 'git cat-file -t candidate'
run 'git cat-file -t v1.0'
run 'for r in HEAD candidate v1.0 "v1.0^{commit}"; do git rev-parse --short "$r"; done'
run 'git cat-file -p v1.0'
cd "$LAB_DIR"

# ---- P2: a ref in two storage places
snip p2-setup
run 'git init -q refstore'
run 'cd refstore'
run 'git commit -q --allow-empty -m "First"'
run 'git branch topic'
run 'git pack-refs --all'
snip p2-answer-a
run 'ls .git/refs/heads'
run 'git branch --list'
snip p2-setup-b
run 'git commit -q --allow-empty -m "Second"'
snip p2-answer-b
run 'ls .git/refs/heads'
run 'cat .git/packed-refs'
run 'git rev-parse main'
cd "$LAB_DIR"

# ---- P3: rev-parse with and without --verify
snip p3-setup
run 'git init -q deployer'
run 'cd deployer'
run 'git commit -q --allow-empty -m "Add the deploy script"'
snip p3-answer
run 'target=$(git rev-parse no-such-branch 2>/dev/null); echo "status=$? target=[$target]"'
run 'target=$(git rev-parse --verify --quiet no-such-branch); echo "status=$? target=[$target]"'
run 'target=$(git rev-parse --verify --quiet "main^{commit}"); echo "status=$? length=${#target}"'
cd "$LAB_DIR"

# ---- G1: HEAD and the refs, as files
snip g1-setup
run 'git init -q labelsync'
run 'cd labelsync'
run 'git commit -q --allow-empty -m "Add the label schema"'
run 'git commit -q --allow-empty -m "Add the export job"'
run 'git branch review HEAD~1'
run 'git tag -a v0.1 -m "First schema" HEAD~1'
run 'git switch -q --detach v0.1'
snip g1-answer
run 'cat .git/HEAD'
run "git for-each-ref --format='%(refname) %(objecttype) %(objectname:short)'"
run 'git log --oneline --graph --all --decorate'
run_rc 'git symbolic-ref HEAD'
cd "$LAB_DIR"

# ---- I1: the modes in a tree
quiet 'git init -q packager'
cd packager || exit 1
printf '#!/bin/sh\necho build\n' > build.sh; chmod +x build.sh
mkdir conf; printf 'env: prod\n' > conf/prod.yaml
ln -s conf/prod.yaml current.yaml
printf '# packager\n' > README.md
quiet 'git add . && git commit -q -m "Add build script and configuration"'
first=$(git rev-parse HEAD)
quiet "git update-index --add --cacheinfo 160000,$first,vendor/tokenizer"
quiet 'git commit -q -m "Record the tokenizer revision"'
snip i1-transcript
run 'git ls-tree HEAD'
run 'git cat-file -p HEAD:current.yaml; echo'
run 'git ls-tree HEAD vendor/'
run_rc 'git cat-file -t HEAD:conf'
cd "$LAB_DIR"

# ---- I2: what git gc changes, and what it does not
quiet 'git init -q housekeeping'
cd housekeeping || exit 1
for n in 1 2 3; do
  printf 'batch: %s\n' "$n" > job.yaml
  quiet "git add job.yaml && git commit -q -m 'Run batch $n'"
done
quiet 'git branch backup'
old=$(git rev-parse --short HEAD)
quiet 'git reset -q --hard HEAD~1'
quiet 'git branch -D backup'
snip i2-transcript
run "git count-objects -v | grep -E '^(count|in-pack|packs):'"
run 'ls .git/refs/heads'
run 'git gc --quiet'
run "git count-objects -v | grep -E '^(count|in-pack|packs):'"
run 'ls .git/refs/heads'
run 'git log --oneline'
run "git cat-file -t $old"
run 'git reflog -2'
lab_end
