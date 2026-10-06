#!/usr/bin/env bash
# Gate 3 (Merge and rebase), prediction part. The pN-setup snippets are printed in the gate
# file, the pN-answer snippets only in the answer key.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin gates g3-predict

# ---- P1: two sides change neighbouring lines
snip p1-setup
run 'git init -q sampler'
run 'cd sampler'
run "printf 'temperature: 0.7\ntop_p: 0.9\ntop_k: 40\nmax_tokens: 512\nseed: 7\n' > sampling.yaml"
run 'git add . && git commit -q -m "Add sampling defaults"'
run 'git switch -q -c tune/top-k'
run "sed -i.bak 's/top_k: 40/top_k: 20/' sampling.yaml && rm sampling.yaml.bak"
run 'git commit -q -am "Lower top_k"'
run 'git switch -q main'
run "sed -i.bak 's/top_p: 0.9/top_p: 0.95/' sampling.yaml && rm sampling.yaml.bak"
run 'git commit -q -am "Raise top_p"'
snip p1-answer
run_rc 'git merge tune/top-k'
run 'git status --short'
run 'git ls-files -u'
run 'cat sampling.yaml'
run 'ls .git | grep -E "MERGE|ORIG|AUTO"'
quiet 'git merge --abort'
cd "$LAB_DIR"

# ---- P2: reset, and reset back
snip p2-setup
run 'git init -q sched'
run 'cd sched'
run "printf 'warmup: 100\n' > lr.yaml"
run 'git add . && git commit -q -m "Add warmup"'
run "printf 'warmup: 500\n' > lr.yaml"
run "printf 'cosine\n' > decay.txt"
run 'git add . && git commit -q -m "Longer warmup, cosine decay"'
run "printf 'warmup: 800\n' > lr.yaml"
run 'git reset -q HEAD~1'
snip p2-answer-a
run 'git status --short'
run 'cat lr.yaml'
run 'git log --oneline'
snip p2-setup-b
run 'git reset -q --soft ORIG_HEAD'
snip p2-answer-b
run 'git log --oneline'
run 'git status --short'
run 'git diff --cached --stat'
cd "$LAB_DIR"

# ---- P3: rebase --onto with stacked branches
snip p3-setup
run 'git init -q stack'
run 'cd stack'
run 'git commit -q --allow-empty -m "A"'
run 'git commit -q --allow-empty -m "B"'
run 'git switch -q -c feature/parser'
run 'git commit -q --allow-empty -m "C"'
run 'git commit -q --allow-empty -m "D"'
run 'git switch -q -c feature/printer'
run 'git commit -q --allow-empty -m "F"'
run 'git commit -q --allow-empty -m "G"'
run 'git switch -q main'
run 'git commit -q --allow-empty -m "E"'
run 'git rebase -q --onto main feature/parser feature/printer'
snip p3-answer
run "git log --graph --all --format='%s%d'"
run 'git branch --show-current'
run 'git log --format=%s main..feature/printer'
run 'git log --format=%s feature/printer..feature/parser'
run 'git log --format=%s ORIG_HEAD -3'
cd "$LAB_DIR"

# ---- P4: ranges and equivalent commits
snip p4-setup
run 'git init -q ranges'
run 'cd ranges'
run "printf 'base\n' > notes.txt && git add . && git commit -q -m 'Base'"
run 'git switch -q -c topic'
run "printf 'p\n' > p.txt && git add . && git commit -q -m 'P'"
run 'git switch -q main'
run "printf 'x\n' > x.txt && git add . && git commit -q -m 'X'"
run "printf 'y\n' > y.txt && git add . && git commit -q -m 'Y'"
run 'git switch -q topic'
run 'git cherry-pick main~1 > /dev/null'
run "printf 'q\n' > q.txt && git add . && git commit -q -m 'Q'"
snip p4-answer
run 'git log --format=%s main..topic'
run 'git log --format="%m %s" --left-right main...topic'
run 'git log --format="%m %s" --left-right --cherry-pick main...topic'
run 'git cherry main topic | cut -c1'
run 'git diff --stat main...topic'
run 'git diff --stat main..topic'
lab_end
