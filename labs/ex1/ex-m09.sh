#!/usr/bin/env bash
# Exercises of Module 9 (rebase; Chapter 9): the model runs behind
# exercises/m06-m10-integration.md and solutions/exercises-m06-m10.md.
# Snippet names start with the exercise number: e04-... belongs to Exercise 9.4.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ex1 ex-m09

# ---- Exercise 9.1 (Level 1): a plain rebase, before and after
snip e01-setup
run 'git init -q guardrails'
run 'cd guardrails'
run "printf 'RULES = []\n' > rules.py"
run 'git add rules.py'
run 'git commit -q -m "Add rule engine"'
run 'git switch -q -c feat/pii'
run "printf 'def has_pii(text):\n    return False\n' > pii.py"
run 'git add pii.py'
run 'git commit -q -m "Add PII rule"'
run "printf 'def has_pii(text):\n    return \"@\" in text\n' > pii.py"
run 'git commit -q -am "Treat an at-sign as PII"'
run 'git switch -q main'
run "printf '# guardrails\n' > README.md"
run 'git add README.md'
run 'git commit -q -m "Add README"'
snip e01-rebase
run 'git switch -q feat/pii'
run 'git log --graph --oneline --all'
run 'git rebase main'
run 'git log --graph --oneline --all'
snip e01-compare
run 'git log --oneline ORIG_HEAD -2'
run 'git range-diff main ORIG_HEAD HEAD'

# ---- Exercise 9.2 (Level 1): fold a fix into the commit it belongs to
snip e02-fixup
run "printf 'def has_pii(text):\n    return \"@\" in text or \"+\" in text\n' > pii.py"
run 'git commit -q -am "fix: phone numbers too"'
run 'git log --oneline main..HEAD'
run_todo '3s/^pick/fixup/' 'git rebase -i main'
run 'git log --oneline main..HEAD'
run 'git show --stat --format=%s HEAD'
cd "$LAB_DIR"

# ---- Exercise 9.3 (Level 1): a conflict, a look around, and the way back
snip e03-setup
run 'git init -q stop-and-go'
run 'cd stop-and-go'
run "printf 'max_len: 100\n' > limits.yaml"
run 'git add limits.yaml'
run 'git commit -q -m "Add limits"'
run 'git switch -q -c feat/longer'
run "printf 'max_len: 500\n' > limits.yaml"
run 'git commit -q -am "Allow 500 characters"'
run 'git switch -q main'
run "printf 'max_len: 200\n' > limits.yaml"
run 'git commit -q -am "Allow 200 characters"'
run 'git switch -q feat/longer'
snip e03-conflict
run_rc 'git rebase main'
run 'git status'
snip e03-state
run 'git branch --show-current'
run 'git log --oneline -1'
run 'ls .git/rebase-merge | sort | head -8'
run 'cat .git/rebase-merge/head-name'
run 'cat limits.yaml'
snip e03-abort
run 'git rebase --abort'
run 'git status -sb'
run 'git log --oneline -1'
run 'cat limits.yaml'
cd "$LAB_DIR"

# ---- Exercise 9.4 (Level 2, draw the graph)
snip e04-setup
run 'git init -q rebase-graph'
run 'cd rebase-graph'
run 'git commit -q --allow-empty -m A'
run 'git commit -q --allow-empty -m B'
run 'git switch -q -c topic'
run 'git commit -q --allow-empty -m C'
run 'git commit -q --allow-empty -m D'
run 'git switch -q main'
run 'git commit -q --allow-empty -m E'
run 'git branch before topic'
run 'git rebase -q main topic'
snip e04-answer
run 'git log --graph --oneline --all'
run 'git branch --show-current'
run 'git reflog show topic'
cd "$LAB_DIR"

# ---- Exercise 9.5 (Level 2, prediction): a commit that main already has
snip e05-setup
run 'git init -q upstream'
run 'cd upstream'
run "printf 'v1\n' > core.txt && git add core.txt && git commit -q -m 'Add core'"
run 'git switch -q -c feat/x'
run "printf 'fix\n' > fix.txt && git add fix.txt && git commit -q -m 'Fix tokenizer crash'"
run "printf 'x\n' > x.txt && git add x.txt && git commit -q -m 'Add feature x'"
run 'git switch -q main'
run 'git cherry-pick feat/x~1'
run "printf 'v2\n' > core.txt && git commit -q -am 'Update core'"
run 'git switch -q feat/x'
snip e05-answer
run 'git rebase main'
run 'git log --oneline main..feat/x'
run 'git log --graph --oneline --all'
cd "$LAB_DIR"

# ---- Exercise 9.6 (Level 2, draw the graph): a merge inside the branch
snip e06-setup
run 'git init -q flatten'
run 'cd flatten'
run 'git commit -q --allow-empty -m A'
run 'git switch -q -c topic'
run 'git commit -q --allow-empty -m B'
run 'git switch -q -c side'
run 'git commit -q --allow-empty -m C'
run 'git switch -q topic'
run 'git commit -q --allow-empty -m D'
run 'git merge -q --no-ff -m M side'
run 'git switch -q main'
run 'git commit -q --allow-empty -m E'
run 'git switch -q topic'
run 'git log --graph --oneline topic main'
snip e06-answer-flat
run 'git rebase -q main'
run 'git log --graph --oneline topic main'
snip e06-answer-merges
run 'git reset -q --hard ORIG_HEAD'
run 'git rebase -q --rebase-merges main'
run 'git log --graph --oneline topic main'
cd "$LAB_DIR"

# ---- Exercise 9.7 (Level 3): a rebase that stopped at an exec line
quiet 'git init exec-stop'
cd exec-stop
quiet "printf 'if grep -q BUG rules.txt; then echo \"check failed: BUG marker in rules.txt\"; exit 1; fi\necho \"check passed\"\n' > check.sh && printf 'rule one\n' > rules.txt && git add . && git commit -m 'Add rules and a check script'"
quiet 'git switch -c feat/more-rules'
quiet "printf 'rule one\nrule two\n' > rules.txt && git commit -am 'Add rule two'"
quiet "printf 'rule one\nrule two\nrule three BUG\n' > rules.txt && git commit -am 'Add rule three'"
quiet "printf 'rule one\nrule two\nrule three BUG\nrule four\n' > rules.txt && git commit -am 'Add rule four'"
quiet 'git switch main'
quiet "printf '# rules\n' > README.md && git add README.md && git commit -m 'Add README'"
quiet 'git switch feat/more-rules'
snip e07-evidence
run_rc "git rebase --exec 'sh ./check.sh' main"
run 'git status'
snip e07-where
run 'git log --oneline main..HEAD'
run 'git log --oneline main..feat/more-rules'
run 'cat .git/rebase-merge/git-rebase-todo | grep -v "^#" | grep .'
snip e07-fix
run "printf 'rule one\nrule two\nrule three\n' > rules.txt"
run 'git commit -q -a --amend --no-edit'
run_rc 'git rebase --continue'
snip e07-finish
note 'The next commit was written on top of the old rule three, so it conflicts with the repair.'
run 'git diff'
run "printf 'rule one\nrule two\nrule three\nrule four\n' > rules.txt"
run 'git add rules.txt'
run 'git rebase --continue'
run 'git log --oneline main..feat/more-rules'
run 'cat rules.txt'
cd "$LAB_DIR"

# ---- Exercise 9.8 (Level 3): the same conflict at every commit
quiet 'git init same-line'
cd same-line
quiet "printf 'batch_size: 8\n' > train.yaml && git add . && git commit -m 'Add training config'"
quiet 'git switch -c feat/bigger-batches'
quiet "printf 'batch_size: 16\n' > train.yaml && git commit -am 'Try batch size 16'"
quiet "printf 'batch_size: 32\n' > train.yaml && git commit -am 'Try batch size 32'"
quiet "printf 'batch_size: 64\n' > train.yaml && git commit -am 'Settle on batch size 64'"
quiet 'git switch main'
quiet "printf 'batch_size: 8  # limited by the 16 GB cards\n' > train.yaml && git commit -am 'Explain the batch size'"
quiet 'git switch feat/bigger-batches'
snip e08-evidence
run_rc 'git rebase main'
run "printf 'batch_size: 16  # limited by the 16 GB cards\n' > train.yaml"
run 'git add train.yaml'
run_rc 'git rebase --continue'
snip e08-count
run 'git rebase --abort'
run 'git log --oneline main..HEAD'
run 'git merge-tree --write-tree --name-only main HEAD | tail -n +2'
snip e08-squash-first
note 'Squash the three steps on their old base first; then one commit meets main once.'
LAB_MSG='Raise the batch size to 64' run_todo '2,$s/^pick/squash/' 'git rebase -i --keep-base main'
run 'git log --oneline main..HEAD'
run_rc 'git rebase main'
run "printf 'batch_size: 64  # needs the 48 GB cards\n' > train.yaml"
run 'git add train.yaml'
run 'git rebase --continue'
run 'git log --graph --oneline --all'
cd "$LAB_DIR"

lab_end
