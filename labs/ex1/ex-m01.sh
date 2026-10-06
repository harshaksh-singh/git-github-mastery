#!/usr/bin/env bash
# Exercises of Module 1 (what Git is; Chapters 1 and 2): the model runs behind
# exercises/m01-m05-foundations.md and solutions/exercises-m01-m05.md.
# Snippet names start with the exercise number: e04-... belongs to Exercise 1.4.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ex1 ex-m01

# ---- Exercise 1.1 (Level 1): one commit, three object types
snip e01-objects
run 'git init chunker'
run 'cd chunker'
run "printf 'def split(text, size):\n    return [text[i:i+size] for i in range(0, len(text), size)]\n' > chunker.py"
run 'git add chunker.py'
run 'git commit -m "Add fixed-size splitter"'
run 'git cat-file -t HEAD'
run 'git cat-file -p HEAD'
run 'git cat-file -p "HEAD^{tree}"'
run 'git cat-file -t HEAD:chunker.py'
run 'git cat-file -p HEAD:chunker.py'
snip e01-files
run 'find .git/objects -type f | sort'
run 'cat .git/HEAD'
run 'cat .git/refs/heads/main'

# ---- Exercise 1.3 (Level 1): the ten-command diagnosis on a small state
snip e03-state
run "printf 'def split(text, size, overlap=0):\n    step = size - overlap\n    return [text[i:i+size] for i in range(0, len(text), step)]\n' > chunker.py"
run "printf 'pytest\n' > requirements-dev.txt"
run 'git add requirements-dev.txt'
run 'git status'
snip e03-diagnosis
run 'git branch -vv'
run 'git remote -v'
run 'git log --graph --decorate --oneline --all'
run 'git diff --stat'
run 'git diff --cached --stat'
run 'git ls-files'
run 'git config list --show-origin --show-scope'
cd "$LAB_DIR"

# ---- Exercise 1.4 (Level 2, prediction): how many objects?
snip e04-count
run 'git init counts'
run 'cd counts'
run "printf 'alpha\n' > a.txt"
run "printf 'beta\n' > b.txt"
run 'mkdir docs'
run "printf 'alpha\n' > docs/a-copy.txt"
run 'git add .'
run 'git commit -q -m "First"'
run "printf 'beta v2\n' > b.txt"
run 'git commit -q -am "Second"'
run "git cat-file --batch-all-objects --batch-check='%(objecttype)' | sort | uniq -c"
snip e04-why
run 'git ls-tree -r HEAD'
run 'git ls-tree HEAD~1'
run 'git ls-tree HEAD'
cd "$LAB_DIR"

# ---- Exercise 1.5 (Level 2, prediction): add twice, commit once
snip e05-twice
run 'git init twice'
run 'cd twice'
run "printf 'draft 1\n' > note.txt"
run 'git add note.txt'
run "printf 'draft 2\n' > note.txt"
run 'git add note.txt'
run 'git commit -q -m "Add note"'
run "git cat-file --batch-all-objects --batch-check='%(objecttype) %(objectname)'"
run 'git ls-tree HEAD'
run 'git fsck'
orphan=$(git fsck 2>/dev/null | awk '/dangling blob/ {print $3}')
run "git cat-file -p ${orphan:0:7}"
cd "$LAB_DIR"

# ---- Exercise 1.6 (Level 2, draw the graph)
snip e06-graph
run 'git init graph'
run 'cd graph'
run 'git commit -q --allow-empty -m A'
run 'git commit -q --allow-empty -m B'
run 'git branch topic'
run 'git commit -q --allow-empty -m C'
run 'git switch -q topic'
run 'git commit -q --allow-empty -m D'
run 'git commit -q --allow-empty -m E'
run 'git tag v1 main'
run 'git switch -q main'
run 'git log --graph --oneline --all'
snip e06-refs
run 'cat .git/HEAD'
run 'git for-each-ref --format="%(refname) %(objectname:short) %(subject)"'
run 'git log --oneline main'
cd "$LAB_DIR"

# ---- Exercise 1.7 (Level 3): same files, different commit IDs
quiet 'git init laptop'
cd laptop
quiet "mkdir prompts && printf 'You are a careful reviewer.\n' > prompts/system.txt && printf 'temperature: 0.2\n' > config.yaml"
quiet 'git add . && git commit -m "Import prompt and config"'
cd "$LAB_DIR"
tick; tick; tick
as asha
quiet 'git init ci-box'
cd ci-box
quiet "mkdir prompts && printf 'You are a careful reviewer.\n' > prompts/system.txt && printf 'temperature: 0.2\n' > config.yaml"
quiet 'git add . && git commit -m "Import prompt and config"'
cd "$LAB_DIR"
as you
snip e07-evidence
run 'git -C laptop log --oneline'
run 'git -C ci-box log --oneline'
run 'git -C laptop status --short'
run 'git -C ci-box status --short'
snip e07-trees
run 'git -C laptop rev-parse "HEAD^{tree}"'
run 'git -C ci-box rev-parse "HEAD^{tree}"'
run 'git -C laptop ls-tree -r HEAD'
run 'git -C ci-box ls-tree -r HEAD'
snip e07-commits
run 'git -C laptop cat-file -p HEAD'
run 'git -C ci-box cat-file -p HEAD'

# ---- Exercise 1.8 (Level 3): an object that no history shows
snip e08-setup
run 'git init vault'
run 'cd vault'
run "printf 'v1\n' > notes.txt"
run 'git add notes.txt'
run 'git commit -q -m "Add notes"'
run "printf '{\"lowercase\": true, \"max_tokens\": 512}\n' > tokenizer.json"
run 'git hash-object -w tokenizer.json'
run 'rm tokenizer.json'
blob=$(printf '{"lowercase": true, "max_tokens": 512}\n' | git hash-object --stdin)
snip e08-evidence
run "git cat-file -p ${blob:0:7}"
run 'git log --oneline --all -- tokenizer.json'
run 'git status --short'
snip e08-diagnosis
run 'git fsck'
run 'git ls-tree -r HEAD'
run 'git clone -q --no-local . ../vault-copy'
run_rc "git -C ../vault-copy cat-file -t ${blob:0:7}"
snip e08-fix
run "git update-index --add --cacheinfo 100644,$blob,tokenizer.json"
run 'git status --short'
run 'git commit -q -m "Add tokenizer settings"'
run 'git restore tokenizer.json'
run 'git ls-tree -r HEAD'
run 'git fsck'
cd "$LAB_DIR"

lab_end
