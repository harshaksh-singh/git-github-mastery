#!/usr/bin/env bash
# Exercises of Module 6 (merge; Chapter 8): the model runs behind
# exercises/m06-m10-integration.md and solutions/exercises-m06-m10.md.
# Snippet names start with the exercise number: e04-... belongs to Exercise 6.4.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ex1 ex-m06

# ---- Exercise 6.1 (Level 1): a fast-forward, then a merge commit
snip e01-ff
run 'git init -q retriever'
run 'cd retriever'
run "printf 'def search(query):\n    return []\n' > search.py"
run 'git add search.py'
run 'git commit -q -m "Add search stub"'
run 'git switch -q -c feature/bm25'
run "printf 'K1 = 1.2\nB = 0.75\n' > bm25.py"
run 'git add bm25.py'
run 'git commit -q -m "Add BM25 parameters"'
run 'git switch -q main'
run 'git merge feature/bm25'
run 'git log --graph --oneline'
snip e01-no-ff
run 'git switch -q -c feature/dense'
run "printf 'DIM = 768\n' > dense.py"
run 'git add dense.py'
run 'git commit -q -m "Add dense retriever settings"'
run 'git switch -q main'
run 'git merge --no-ff -m "Merge feature/dense" feature/dense'
run 'git log --graph --oneline'
run 'git cat-file -p HEAD'
cd "$LAB_DIR"

# ---- Exercise 6.2 (Level 1): the merge base and the rule table
snip e02-base
run 'git init -q rules'
run 'cd rules'
run "printf 'top_k: 5\nmetric: cosine\nrerank: false\n' > search.yaml"
run 'git add search.yaml'
run 'git commit -q -m "Add search settings"'
run 'git switch -q -c feature/rerank'
run "printf 'top_k: 5\nmetric: cosine\nrerank: true\n' > search.yaml"
run 'git commit -q -am "Switch reranking on"'
run 'git switch -q main'
run "printf 'top_k: 10\nmetric: cosine\nrerank: false\n' > search.yaml"
run 'git commit -q -am "Return ten hits"'
run 'git merge-base main feature/rerank'
run 'git show "$(git merge-base main feature/rerank)":search.yaml'
snip e02-merge
run 'git merge -m "Merge feature/rerank" feature/rerank'
run 'cat search.yaml'
run 'git log --graph --oneline'
cd "$LAB_DIR"

# ---- Exercise 6.3 (Level 1): one conflict, resolved step by step
snip e03-conflict
run 'git init -q conflict'
run 'cd conflict'
run "printf 'model: small\n' > model.yaml"
run 'git add model.yaml'
run 'git commit -q -m "Add model setting"'
run 'git switch -q -c exp/large'
run "printf 'model: large\n' > model.yaml"
run 'git commit -q -am "Use the large model"'
run 'git switch -q main'
run "printf 'model: medium\n' > model.yaml"
run 'git commit -q -am "Use the medium model"'
run_rc 'git merge exp/large'
run 'git status'
snip e03-look
run 'cat model.yaml'
run 'git ls-files -u'
run 'ls .git | grep MERGE'
snip e03-resolve
run "printf 'model: large\n' > model.yaml"
run 'git add model.yaml'
run 'git status --short'
run 'git merge --continue'
run 'git log --graph --oneline'
cd "$LAB_DIR"

# ---- Exercise 6.4 (Level 2, draw the graph)
snip e04-setup
run 'git init -q shape'
run 'cd shape'
run 'git commit -q --allow-empty -m A'
run 'git commit -q --allow-empty -m B'
run 'git switch -q -c f1'
run 'git commit -q --allow-empty -m C'
run 'git commit -q --allow-empty -m D'
run 'git switch -q main'
run 'git commit -q --allow-empty -m E'
run 'git switch -q -c f2'
run 'git commit -q --allow-empty -m F'
run 'git switch -q main'
run 'git merge -q --no-ff -m M1 f1'
run 'git merge -q -m M2 f2'
snip e04-answer
run 'git log --graph --oneline'
run 'git log --first-parent --oneline'
run 'git show -s --format="%s: parents %p" HEAD HEAD~1'
cd "$LAB_DIR"

# ---- Exercise 6.5 (Level 2, prediction): what a squash leaves behind
snip e05-setup
run 'git init -q squash'
run 'cd squash'
run "printf 'v1\n' > core.txt"
run 'git add core.txt'
run 'git commit -q -m "Add core"'
run 'git switch -q -c feature/x'
run "printf 'one\n' > x1.txt"
run 'git add x1.txt'
run 'git commit -q -m "Add x1"'
run "printf 'two\n' > x2.txt"
run 'git add x2.txt'
run 'git commit -q -m "Add x2"'
run 'git switch -q main'
run 'git merge --squash feature/x'
snip e05-answer-a
run 'git status --short'
run 'git log --oneline'
run 'ls .git | grep -E "MERGE|SQUASH"'
snip e05-answer-b
run 'git commit -q -m "Add x (squashed)"'
run 'git log --graph --oneline --all'
run 'git show -s --format="parents: %p" HEAD'
run 'git branch --merged main'
run_rc 'git branch -d feature/x'
cd "$LAB_DIR"

# ---- Exercise 6.6 (Level 2, prediction): which of three changes conflicts?
snip e06-setup
run 'git init -q regions'
run 'cd regions'
run "printf 'a: 1\nb: 2\nc: 3\nd: 4\ne: 5\nf: 6\n' > params.yaml"
run 'git add params.yaml'
run 'git commit -q -m "Add parameters"'
run 'git switch -q -c topic'
run "printf 'a: 1\nb: 20\nc: 3\nd: 40\ne: 5\nf: 60\n' > params.yaml"
run 'git commit -q -am "Topic: change b, d and f"'
run 'git switch -q main'
run "printf 'a: 10\nb: 2\nc: 3\nd: 40\ne: 5\nf: 6\n' > params.yaml"
run 'git commit -q -am "Main: change a and d"'
snip e06-answer
run_rc 'git merge topic'
run 'cat params.yaml'
run 'git diff'
cd "$LAB_DIR"

# ---- Exercise 6.7 (Level 3): "Already up to date", and the change is not there
quiet 'git init ranker-tuning'
cd ranker-tuning
quiet "mkdir ranker && printf 'K1 = 1.2\nB = 0.75\n' > ranker/bm25.py && printf '# ranker-tuning\n' > README.md && git add . && git commit -m 'Add BM25 parameters'"
quiet 'git switch -c feature/bm25-tuning'
quiet "printf 'K1 = 1.6\nB = 0.75\n' > ranker/bm25.py && git commit -am 'Raise k1 after the grid search'"
quiet "printf 'K1 = 1.6\nB = 0.6\n' > ranker/bm25.py && git commit -am 'Lower b for short documents'"
quiet 'git switch main'
quiet "printf '# ranker-tuning\n\nBM25 parameters for the support corpus.\n' > README.md && git commit -am 'Describe the project'"
as asha
quiet 'git merge -s ours -m "Merge feature/bm25-tuning" feature/bm25-tuning'
as you
quiet "printf '# ranker-tuning\n\nBM25 parameters for the support corpus.\n\nOwner: search team.\n' > README.md && git commit -am 'Name the owner'"
snip e07-evidence
run 'git merge feature/bm25-tuning'
run 'git branch --merged main'
run 'git show main:ranker/bm25.py'
run 'git show feature/bm25-tuning:ranker/bm25.py'
run 'git log --graph --oneline'
snip e07-diagnosis
run "git log --merges --format='%h %an: %s (parents %p)'"
m=$(git log --merges --format=%h -1)
run "git diff --stat $m^1 $m"
run "git diff --stat $m^2 $m"
run "git show --remerge-diff --format='%h %s' $m"
snip e07-fix
note 'The merge recorded ancestry without content, so the content has to arrive as new commits.'
run "git cherry-pick -x $m^1..$m^2"
run 'git show main:ranker/bm25.py'
run 'git log --graph --oneline'
cd "$LAB_DIR"

# ---- Exercise 6.8 (Level 3): conflict markers in main
quiet 'git init prompt-lib'
cd prompt-lib
quiet "mkdir prompts && printf 'You are a support assistant.\nAnswer in two sentences.\nCite the knowledge base article.\n' > prompts/support.txt && git add . && git commit -m 'Add support prompt'"
quiet 'git switch -c feature/tone'
quiet "printf 'You are a friendly support assistant.\nAnswer in two sentences.\nCite the knowledge base article.\n' > prompts/support.txt && git commit -am 'Make the assistant friendly'"
quiet 'git switch main'
quiet "printf 'You are a support assistant for Acme.\nAnswer in two sentences.\nCite the knowledge base article.\n' > prompts/support.txt && git commit -am 'Name the company'"
as ravi
quiet 'git merge feature/tone'
quiet 'git add prompts/support.txt && git commit --no-edit'
as you
quiet "printf 'timeout_s: 30\n' > settings.yaml && git add settings.yaml && git commit -m 'Add request timeout'"
snip e08-evidence
run "git grep -n -e '^<<<<<<<' -e '^=======' -e '^>>>>>>>' -- prompts"
run 'git log --graph --oneline'
snip e08-diagnosis
note 'A plain pickaxe walk shows no diff for merge commits, so it cannot name one.'
run "git log --oneline -S'<<<<<<<' -- prompts/support.txt"
run "git log --oneline -m -S'<<<<<<<' -- prompts/support.txt"
m=$(git log --merges --format=%h -1)
run "git show -s --format='%h %an <%ae>%n%s' $m"
run "git show --remerge-diff --format='remerge-diff of %h:' $m"
run "git diff --check $m^1 $m"
snip e08-fix
run "printf 'You are a friendly support assistant for Acme.\nAnswer in two sentences.\nCite the knowledge base article.\n' > prompts/support.txt"
run 'git commit -q -am "Resolve the conflict that was committed with its markers"'
run_rc "git grep -n -e '^<<<<<<<' -e '^=======' -e '^>>>>>>>' -- prompts"
run 'git log --graph --oneline -3'
cd "$LAB_DIR"

lab_end
