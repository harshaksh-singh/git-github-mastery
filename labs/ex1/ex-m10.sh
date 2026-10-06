#!/usr/bin/env bash
# Exercises of Module 10 (cherry-pick and ranges; Chapter 10 and Chapter 14A, sections 14A.7,
# 14A.8 and 14A.14): the model runs behind exercises/m06-m10-integration.md and
# solutions/exercises-m06-m10.md.
# Snippet names start with the exercise number: e04-... belongs to Exercise 10.4.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ex1 ex-m10

# ---- Exercise 10.1 (Level 1): one commit, copied to another branch
snip e01-setup
run 'git init -q tokenlab'
run 'cd tokenlab'
run "printf 'def tokenize(text):\n    return text.split()\n' > tokenizer.py"
run 'git add tokenizer.py'
run 'git commit -q -m "Add whitespace tokenizer"'
run 'git branch release/1.0'
run "printf 'hello\nworld\n' > vocab.txt"
run 'git add vocab.txt'
run 'git commit -q -m "Add vocabulary file"'
run "printf 'def tokenize(text):\n    return text.split() if text else []\n' > tokenizer.py"
run 'git commit -q -am "Return an empty list for empty input"'
snip e01-pick
run 'git switch -q release/1.0'
run 'git cherry-pick main'
run 'git log --graph --oneline --all'
snip e01-compare
run "git log -1 --format='%h  author %an %ad  |  committer %cd' --date=format:%H:%M main"
run "git log -1 --format='%h  author %an %ad  |  committer %cd' --date=format:%H:%M release/1.0"
run 'git range-diff main^! release/1.0^!'
run 'ls'

# ---- Exercise 10.3 (Level 1): two commits picked as one
snip e03-no-commit
run 'git switch -q main'
run "printf 'LOWERCASE = False\n' > options.py"
run 'git add options.py'
run 'git commit -q -m "Add lowercase option"'
run "printf '# tokenlab\n\nSet LOWERCASE in options.py to fold case.\n' > README.md"
run 'git add README.md'
run 'git commit -q -m "Document the lowercase option"'
run 'git switch -q release/1.0'
run 'git cherry-pick -n main~1 main'
run 'git status --short'
run 'git log --oneline -1'
run 'git commit -q -m "Backport the lowercase option and its documentation"'
run 'git show --stat --format="%h %s" HEAD'
cd "$LAB_DIR"

# ---- Exercise 10.2 (Level 1): names for commits
quiet 'git init selectors'
cd selectors
quiet "printf 'a\n' > a.txt && git add . && git commit -m 'Add a'"
quiet "printf 'b\n' > b.txt && git add . && git commit -m 'Add b'"
quiet 'git switch -c side'
quiet "printf 's1\n' > s1.txt && git add . && git commit -m 'Add s1'"
quiet "printf 's2\n' > s2.txt && git add . && git commit -m 'Add s2'"
quiet 'git switch main'
quiet "printf 'c\n' > c.txt && git add . && git commit -m 'Add c'"
quiet 'git merge --no-ff -m "Merge side" side'
quiet "printf 'd\n' > d.txt && git add . && git commit -m 'Add d'"
snip e02-graph
run 'git log --graph --oneline'
snip e02-selectors
run "git show -s --format=%s HEAD~1"
run "git show -s --format=%s HEAD~2"
run "git show -s --format=%s 'HEAD~1^2'"
run "git show -s --format=%s 'HEAD~1^2~1'"
run "git show -s --format=%s 'HEAD^^^'"
run "git show -s --format=%s ':/Add s'"
run "git show -s --format=%s 'main@{1}'"
run "git cat-file -t 'HEAD^{tree}'"
run "git cat-file -p HEAD~1:s2.txt"
cd "$LAB_DIR"

# ---- Exercise 10.4 (Level 2, prediction): ranges on a history with a merge
snip e04-setup
run 'git init -q ranges'
run 'cd ranges'
run 'git commit -q --allow-empty -m A'
run 'git commit -q --allow-empty -m B'
run 'git switch -q -c topic'
run 'git commit -q --allow-empty -m C'
run 'git commit -q --allow-empty -m D'
run 'git switch -q main'
run 'git commit -q --allow-empty -m E'
run 'git switch -q topic'
run 'git merge -q -m M main'
run 'git commit -q --allow-empty -m F'
run 'git switch -q main'
run 'git commit -q --allow-empty -m G'
snip e04-answer
run 'git log --oneline main..topic'
run 'git log --oneline topic..main'
run 'git log --oneline --left-right main...topic'
run 'git rev-list --left-right --count main...topic'
run 'git log --oneline --no-merges topic ^main'
run 'git log --oneline "topic~1^!"'
snip e04-graph
run 'git log --graph --oneline --all'
cd "$LAB_DIR"

# ---- Exercise 10.5 (Level 2, prediction): which commits does a range pick?
snip e05-setup
run 'git init -q pick-range'
run 'cd pick-range'
run "printf 'base\n' > base.txt && git add . && git commit -q -m 'Base'"
run 'git branch release'
run "printf 'a\n' > a.txt && git add . && git commit -q -m 'Add a'"
run "printf 'b\n' > b.txt && git add . && git commit -q -m 'Add b'"
run "printf 'c\n' > c.txt && git add . && git commit -q -m 'Add c'"
run "printf 'd\n' > d.txt && git add . && git commit -q -m 'Add d'"
run 'git switch -q release'
run 'git cherry-pick main~3..main~1'
snip e05-answer
run 'git log --oneline'
run 'ls'
run 'git cherry -v release main'
cd "$LAB_DIR"

# ---- Exercise 10.6 (Level 2, draw the graph): backport, then merge the release back
snip e06-setup
run 'git init -q backport'
run 'cd backport'
run "printf 'base\n' > base.txt && git add . && git commit -q -m 'A'"
run 'git branch release/2.1'
run "printf 'feature\n' > feature.txt && git add . && git commit -q -m 'B: feature'"
run "printf 'fix one\n' > fix1.txt && git add . && git commit -q -m 'C: fix one'"
run "printf 'fix two\n' > fix2.txt && git add . && git commit -q -m 'D: fix two'"
run 'git switch -q release/2.1'
run 'git cherry-pick -x main~1 main > /dev/null'
run 'git switch -q main'
snip e06-before-merge
run 'git log --oneline --left-right --cherry-mark main...release/2.1'
snip e06-answer
run 'git merge -m "Merge release/2.1 into main" release/2.1'
run 'git log --graph --oneline --all'
run 'git log --oneline main | grep -c fix'
run 'git log -1 --format=%B release/2.1'
cd "$LAB_DIR"

# ---- Exercise 10.7 (Level 3): "The previous cherry-pick is now empty"
quiet 'git init empty-pick'
cd empty-pick
quiet "printf 'timeout_s: 30\n' > client.yaml && git add . && git commit -m 'Add client settings'"
quiet 'git branch release/4.0'
quiet "printf 'retries: 3\n' > retry.yaml && git add retry.yaml && git commit -m 'Add retries'"
quiet "printf 'timeout_s: 120\n' > client.yaml && git commit -am 'Raise the timeout for long documents'"
quiet 'git switch release/4.0'
as ravi
quiet "printf 'timeout_s: 120\n' > client.yaml && git commit -am 'Hotfix: timeouts on long documents'"
as you
snip e07-evidence
run 'git log --oneline --graph --all'
run_rc 'git cherry-pick -x main'
snip e07-diagnosis
run_rc 'git diff --quiet HEAD'
run 'git show --format="%h %an: %s" HEAD'
run 'git show --format="%h %an: %s" CHERRY_PICK_HEAD'
run 'git cherry -v release/4.0 main'
snip e07-exit
run 'git cherry-pick --skip'
run 'git status -sb'
run 'git log --oneline -2'
cd "$LAB_DIR"

# ---- Exercise 10.8 (Level 3): a clean pick that does not work
quiet 'git init needs-more'
cd needs-more
quiet "printf 'def tokenize(text):\n    return text.split()\n' > tok.py && git add . && git commit -m 'Add tokenizer'"
quiet 'git branch release/1.0'
quiet "printf 'def normalize(text):\n    return text.strip().lower()\n' > text.py && git add . && git commit -m 'Add normalize() helper'"
quiet "printf '# tokenizer\n' > README.md && git add . && git commit -m 'Add README'"
quiet "printf 'from text import normalize\n\ndef tokenize(text):\n    return normalize(text).split()\n' > tok.py && git commit -am 'Normalize the text before tokenizing'"
quiet 'git switch release/1.0'
snip e08-evidence
run 'git cherry-pick -x main'
run 'git status -sb'
run 'cat tok.py'
run 'ls'
snip e08-diagnosis
run 'git grep -n normalize'
run "git log --oneline -S'def normalize' main"
run 'git cherry -v release/1.0 main'
run 'git log --oneline --stat release/1.0..main -- text.py'
snip e08-fix
note 'The pick is private: take it back, then pick both commits in the order main has them.'
run 'git reset -q --hard HEAD~1'
dep=$(git log --format=%h -1 --grep='Add normalize' main)
run "git cherry-pick -x $dep main > /dev/null"
run 'git log --oneline'
run 'ls'
cd "$LAB_DIR"

lab_end
