#!/usr/bin/env bash
# Exercises of Module 8 (undo; Chapter 11): the model runs behind
# exercises/m06-m10-integration.md and solutions/exercises-m06-m10.md.
# Snippet names start with the exercise number: e04-... belongs to Exercise 8.4.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ex1 ex-m08

# ---- Exercise 8.1 (Level 1): take a commit back and make it again
snip e01-soft
run 'git init -q eval-runner'
run 'cd eval-runner'
run "printf 'def run(case):\n    return case.execute()\n' > runner.py"
run 'git add runner.py'
run 'git commit -q -m "Add runner"'
run "printf 'def run(case):\n    return case.execute(timeout=30)\n' > runner.py"
run 'git commit -q -am "wip"'
run 'git reset --soft HEAD~1'
run 'git status --short'
run 'git diff --cached --stat'
run 'git log --oneline'
run 'git commit -q -m "Give every case a 30 second timeout"'
run 'git log --oneline'
run 'git reflog -4'

# ---- Exercise 8.2 (Level 1): revert a commit that is not the last one
snip e02-revert
run "printf 'retries: 5\n' > retry.yaml"
run 'git add retry.yaml'
run 'git commit -q -m "Retry five times"'
run "printf '# eval-runner\n' > README.md"
run 'git add README.md'
run 'git commit -q -m "Add README"'
run 'git revert --no-edit HEAD~1'
run 'git log --oneline'
run 'git show --stat --format="%s%n%n%b" HEAD'
run 'ls'

# ---- Exercise 8.3 (Level 1): park an edit and bring it back
snip e03-stash
run "printf 'def run(case):\n    return case.execute(timeout=60)\n' > runner.py"
run 'git stash push -m "try a longer timeout"'
run 'git status --short'
run 'git stash list'
run 'git stash show -p'
run 'git stash apply'
run 'git stash list'
run 'git stash drop'
run 'git status --short'
cd "$LAB_DIR"

# ---- Exercise 8.4 (Level 2, prediction): reset --keep, twice
snip e04-setup
run 'git init -q keep'
run 'cd keep'
run "printf 'a1\n' > a.txt"
run "printf 'b1\n' > b.txt"
run 'git add .'
run 'git commit -q -m "Base"'
run "printf 'a2\n' > a.txt"
run 'git commit -q -am "Change a"'
run "printf 'b2\n' > b.txt"
snip e04-answer-a
run_rc 'git reset --keep HEAD~1'
run 'git status --short'
run 'cat a.txt b.txt'
run 'git log --oneline'
snip e04-setup-b
run 'git reset -q --keep ORIG_HEAD'
run 'git log --oneline'
run "printf 'a3\n' > a.txt"
snip e04-answer-b
run_rc 'git reset --keep HEAD~1'
run 'git status --short'
run 'cat a.txt b.txt'
run 'git log --oneline'
cd "$LAB_DIR"

# ---- Exercise 8.5 (Level 2, prediction): revert a range
snip e05-setup
run 'git init -q revert-range'
run 'cd revert-range'
run "printf 'a\n' > a.txt && git add a.txt && git commit -q -m 'Add a'"
run "printf 'b\n' > b.txt && git add b.txt && git commit -q -m 'Add b'"
run "printf 'c\n' > c.txt && git add c.txt && git commit -q -m 'Add c'"
run "printf 'd\n' > d.txt && git add d.txt && git commit -q -m 'Add d'"
run 'git revert --no-edit HEAD~2..HEAD'
snip e05-answer
run 'git log --oneline'
run 'ls'
run_rc 'git diff --quiet HEAD~4 HEAD'
run 'git rev-list --count HEAD'
cd "$LAB_DIR"

# ---- Exercise 8.6 (Level 2, draw the graph): after a hard reset
snip e06-setup
run 'git init -q undo-graph'
run 'cd undo-graph'
run 'git commit -q --allow-empty -m A'
run 'git commit -q --allow-empty -m B'
run 'git commit -q --allow-empty -m C'
run 'git branch backup'
run 'git reset -q --hard HEAD~2'
run 'git commit -q --allow-empty -m D'
snip e06-answer
run 'git log --graph --oneline --all'
run 'git show -s --format=%s ORIG_HEAD'
run 'git reflog'
snip e06-without-backup
run 'git branch -q -D backup'
run 'git log --graph --oneline --all'
run 'git show -s --format=%s ORIG_HEAD'
run 'git show -s --format=%s "main@{2}"'
cd "$LAB_DIR"

# ---- Exercise 8.7 (Level 3): the commit that came back
mkdir -p "$LAB_DIR/m08-ex7" && cd "$LAB_DIR/m08-ex7"
quiet 'git init --bare server.git'
quiet 'git clone server.git you'
cd you
quiet "printf 'PASS_MARK = 0.7\n' > threshold.py && git add . && git commit -m 'Add pass mark' && git push -u origin main"
quiet "printf 'PASS_MARK = 0.0\n' > threshold.py && git commit -am 'Debug: let everything pass' && git push"
snip e07-evidence
run 'git log --oneline'
run 'git reset --hard HEAD~1'
run 'git status -sb'
run_rc 'git push'
run 'git pull'
run 'git log --oneline'
snip e07-diagnosis
run 'git reflog -4'
run 'git status -sb'
snip e07-fix
run 'git revert --no-edit HEAD'
run 'git push'
run 'git log --oneline'
run 'cat threshold.py'
cd "$LAB_DIR"

# ---- Exercise 8.8 (Level 3): what a hard reset took and what it left
snip e08-setup
run 'git init -q lost'
run 'cd lost'
run "printf 'def run(case):\n    return case.execute()\n' > runner.py"
run 'git add runner.py'
run 'git commit -q -m "Add runner"'
run 'mkdir eval'
run "printf 'def f1(p, r):\n    return 2 * p * r / (p + r)\n' > eval/metrics.py"
run 'git add eval/metrics.py'
run "printf 'ask Asha about macro F1\n' > notes.txt"
run "printf 'def run(case):\n    return case.execute(timeout=30)\n' > runner.py"
run 'git status --short'
run 'git reset --hard'
snip e08-observed
run 'git status --short'
run 'ls'
run 'cat runner.py'
snip e08-recover
run 'git fsck'
blob=$(git fsck 2>/dev/null | awk '/dangling blob/ {print $3}')
run "git cat-file -p ${blob:0:7}"
run "mkdir -p eval && git cat-file -p ${blob:0:7} > eval/metrics.py"
run 'git status --short'
cd "$LAB_DIR"

lab_end
