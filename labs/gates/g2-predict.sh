#!/usr/bin/env bash
# Gate 2 (Branching), prediction part. The pN-setup snippets are printed in the gate file,
# the pN-answer snippets only in the answer key.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin gates g2-predict

# One server and two clones, shared by P1, P3 and P4 (each item gets fresh copies).
mk() {   # mk <dir>: server.git, you/ and asha/ with two commits on main
  mkdir "$1" && cd "$1" || exit 1
  quiet 'git init --bare server.git'
  quiet 'git clone server.git you'
  quiet 'git -C you remote set-url origin ../server.git'
  cd you || exit 1
  quiet 'git commit --allow-empty -m "Add tokenizer"'
  quiet 'git commit --allow-empty -m "Add vocabulary loader"'
  quiet 'git push -u origin main'
  cd ..
  quiet 'git clone server.git asha'
  quiet 'git -C asha remote set-url origin ../server.git'
  cd you || exit 1
}

# ---- P1: ahead and behind are computed from two local refs
mk p1
snip p1-setup
note 'you/ and asha/ are clones of the same server. main has two commits everywhere.'
run 'git commit -q --allow-empty -m "Cache the vocabulary"'
run 'git commit -q --allow-empty -m "Add cache eviction"'
as asha
run 'git -C ../asha commit -q --allow-empty -m "Fix unicode normalization"'
run 'git -C ../asha push -q origin main'
as you
run 'git status -sb'
run 'git fetch -q'
snip p1-answer
run 'git status -sb'
run 'git rev-list --left-right --count main...origin/main'
run_rc 'git merge-base --is-ancestor origin/main main'
run 'git log --oneline main..origin/main'
cd "$LAB_DIR"

# ---- P2: ancestry questions
snip p2-setup
run 'git init -q tokenizer'
run 'cd tokenizer'
run 'git commit -q --allow-empty -m "A"'
run 'git branch fix/bpe'
run 'git commit -q --allow-empty -m "B"'
run 'git branch feature/cache'
run 'git switch -q -c feature/stream'
run 'git commit -q --allow-empty -m "C"'
run 'git switch -q main'
run 'git commit -q --allow-empty -m "D"'
snip p2-answer
run 'git branch --merged main'
run 'git branch --no-merged main'
run 'git branch --contains feature/cache'
run 'git log --oneline --graph --all'
run_rc 'git branch -d feature/cache'
cd "$LAB_DIR"

# ---- P3: git pull on diverged branches, nothing configured
mk p3
snip p3-setup
note 'you/ and asha/ are clones of the same server. main has two commits everywhere.'
note 'Neither pull.rebase nor pull.ff is set.'
run 'git commit -q --allow-empty -m "Cache the vocabulary"'
as asha
run 'git -C ../asha commit -q --allow-empty -m "Fix unicode normalization"'
run 'git -C ../asha push -q origin main'
as you
run 'git log -1 --format=%s origin/main'
run_rc 'git pull -q'
snip p3-answer
run 'git log -1 --format=%s origin/main'
run 'git log -1 --format=%s main'
run 'git status -sb'
run_rc 'git pull --ff-only'
run 'git log --oneline --graph --all'
cd "$LAB_DIR"

# ---- P4: a branch deleted on the server
mk p4
snip p4-setup
note 'you/ and asha/ are clones of the same server. main has two commits everywhere.'
run 'git switch -q -c feature/streaming'
run 'git commit -q --allow-empty -m "Stream tokens"'
run 'git push -q -u origin feature/streaming'
run 'git switch -q main'
as asha
run 'git -C ../asha push -q origin --delete feature/streaming'
as you
run 'git fetch'
snip p4-answer-a
run 'git branch -r'
run 'git branch -vv'
snip p4-setup-b
run 'git fetch -q --prune'
snip p4-answer-b
run 'git branch -vv'
run_rc 'git branch -d feature/streaming'
run_rc 'git push origin feature/streaming'
run 'git branch -r'
lab_end
