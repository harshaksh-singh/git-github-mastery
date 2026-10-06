#!/usr/bin/env bash
# Exercises of Module 2 (working tree, index, HEAD; Chapters 4 and 5): the model runs behind
# exercises/m01-m05-foundations.md and solutions/exercises-m01-m05.md.
# Snippet names start with the exercise number: e04-... belongs to Exercise 2.4.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ex1 ex-m02

# ---- Exercise 2.1 (Level 1): every short status code, made on purpose
quiet 'git init label-audit'
cd label-audit
quiet "printf 'def audit(rows):\n    return [r for r in rows if r.label is None]\n' > audit.py"
quiet "printf 'id,label\n1,spam\n2,ham\n' > labels.csv"
quiet "printf '# label-audit\n' > README.md"
quiet "printf 'rule: none\n' > old_rules.txt"
quiet "printf 'def legacy():\n    pass\n' > legacy.py"
quiet "printf 'def load(path):\n    return open(path).read().splitlines()\n' > loader.py"
quiet 'git add . && git commit -m "Import label audit"'
snip e01-status
run "printf 'ideas\n' > notes.md"
run "printf 'def report(rows):\n    return len(rows)\n' > report.py"
run 'git add report.py'
run "printf 'def audit(rows):\n    return [r for r in rows if not r.label]\n' > audit.py"
run "printf '# label-audit\n\nFinds rows without a label.\n' > README.md"
run 'git add README.md'
run "printf 'id,label\n1,spam\n2,ham\n3,spam\n' > labels.csv"
run 'git add labels.csv'
run "printf 'id,label\n1,spam\n2,ham\n3,spam\n4,ham\n' > labels.csv"
run 'rm old_rules.txt'
run 'git rm -q legacy.py'
run 'git mv loader.py reader.py'
run 'git status --short'
snip e01-long
run 'git status'
cd "$LAB_DIR"

# ---- Exercise 2.2 (Level 1): which rule ignores which path
snip e02-ignore
run 'git init -q ignore-rules'
run 'cd ignore-rules'
run "printf '*.log\n/build/\ndata/*\n!data/README.md\n.env*\n!.env.example\n' > .gitignore"
run 'cat -n .gitignore'
run 'git check-ignore -v -n app.log logs/app.log build/out.bin src/build/out.bin data/train.csv data/README.md .env.local .env.example'
cd "$LAB_DIR"

# ---- Exercise 2.3 (Level 1): three diffs
snip e03-diffs
run 'git init -q three-diffs'
run 'cd three-diffs'
run "printf 'min_agreement: 0.80\n' > thresholds.yaml"
run 'git add thresholds.yaml'
run 'git commit -q -m "Add thresholds"'
run "printf 'min_agreement: 0.85\n' > thresholds.yaml"
run 'git add thresholds.yaml'
run "printf 'min_agreement: 0.90\n' > thresholds.yaml"
run 'git diff'
run 'git diff --cached'
run 'git diff HEAD'
cd "$LAB_DIR"

# ---- Exercise 2.4 (Level 2, prediction): what does the commit contain?
snip e04-setup
run 'git init -q staged'
run 'cd staged'
run "printf 'retries: 1\n' > job.yaml"
run 'git add job.yaml'
run 'git commit -q -m "Add job config"'
run "printf 'retries: 2\n' > job.yaml"
run 'git add job.yaml'
run "printf 'retries: 3\n' > job.yaml"
run 'git commit -q -m "Raise retries"'
snip e04-answer
run 'git show HEAD:job.yaml'
run 'cat job.yaml'
run 'git status --short'
run 'git diff'
run 'git ls-files --stage'
cd "$LAB_DIR"

# ---- Exercise 2.5 (Level 2, prediction): negation and an excluded directory
snip e05-setup
run 'git init -q ignore-trap'
run 'cd ignore-trap'
run 'mkdir -p data/raw models'
run "printf 'x\n' > data/raw/a.csv"
run "printf 'Run scripts/fetch.sh to download the data.\n' > data/README.md"
run "printf 'weights\n' > models/best.ckpt"
run "printf 'weights\n' > models/tiny.ckpt"
run "printf 'data/\n!data/README.md\n*.ckpt\n!models/tiny.ckpt\n' > .gitignore"
snip e05-answer
run 'git status --short --untracked-files=all'
run_rc 'git check-ignore -v data/README.md'
run_rc 'git check-ignore -v models/tiny.ckpt'
run_rc 'git check-ignore -v models/best.ckpt'
snip e05-fix
run "printf 'data/*\n!data/README.md\n*.ckpt\n!models/tiny.ckpt\n' > .gitignore"
run 'git status --short --untracked-files=all'
run_rc 'git check-ignore -v data/README.md'
run 'git check-ignore -v data/raw/a.csv'
cd "$LAB_DIR"

# ---- Exercise 2.6 (Level 2): a rename and an edit as two commits
quiet 'git init split-rename'
cd split-rename
quiet "printf 'import json\n\n\ndef train(config_path):\n    config = json.load(open(config_path))\n    epochs = config[\"epochs\"]\n    for epoch in range(epochs):\n        print(\"epoch\", epoch)\n    return epochs\n' > train.py"
quiet 'git add train.py && git commit -m "Add training loop"'
snip e06-rename
run 'mkdir trainer'
run 'git mv train.py trainer/run.py'
run 'git status --short'
run 'git commit -q -m "Move training loop into the trainer package"'
run "sed -e 's/print(\"epoch\", epoch)/print(\"epoch\", epoch + 1, \"of\", epochs)/' trainer/run.py > run.tmp && mv run.tmp trainer/run.py"
run 'git commit -q -am "Print one-based epoch numbers"'
snip e06-verify
run 'git show --stat --format=%s HEAD~1'
run 'git show --stat --format=%s HEAD'
run 'git log --oneline --follow -- trainer/run.py'
run 'git log --oneline -- trainer/run.py'
cd "$LAB_DIR"

# ---- Exercise 2.7 (Level 3): "git restore ." did not discard everything
snip e07-setup
run 'git init -q discard'
run 'cd discard'
run "printf 'k: 5\n' > retrieval.yaml"
run "printf 'model: small\n' > model.yaml"
run 'git add .'
run 'git commit -q -m "Add configs"'
run "printf 'k: 50\n' > retrieval.yaml"
run "printf 'model: large\n' > model.yaml"
run 'git add model.yaml'
run "printf 'scratch\n' > notes.md"
run 'git status --short'
run 'git restore .'
run 'git status --short'
snip e07-explain
run 'cat retrieval.yaml model.yaml'
run 'git diff --cached'
snip e07-discard
run 'git restore --staged --worktree .'
run 'git status --short'
run 'git clean -n'
run 'git clean -f'
run 'git status --short'
cd "$LAB_DIR"

# ---- Exercise 2.8 (Level 3): "git commit <path>" after "git add -p"
quiet 'git init partial'
cd partial
quiet "printf 'def exact_match(a, b):\n    return a == b\n\n\n\n\n\n\n\ndef normalize(s):\n    return s\n' > metrics.py"
quiet "printf '# metrics\n' > README.md"
quiet 'git add . && git commit -m "Add metrics"'
quiet "printf 'def exact_match(a, b):\n    return normalize(a) == normalize(b)\n\n\n\n\n\n\n\ndef normalize(s):\n    return s.strip().lower()  # experiment: also strip punctuation?\n' > metrics.py"
quiet "printf '# metrics\n\nExact match after normalization.\n' > README.md"
quiet 'git add README.md'
quiet "printf 'y\nn\n' | git add -p metrics.py"
snip e08-before
run 'git status --short'
run 'git diff --cached -- metrics.py'
run 'git diff -- metrics.py'
snip e08-commit
run 'git commit -m "Compare normalized strings" metrics.py'
run 'git status --short'
run 'git show --format=%s HEAD'
snip e08-redo
note 'The commit is private, so it can be taken back and made again from the index.'
run 'git reset -q --soft HEAD~1'
run 'git restore --staged README.md metrics.py'
run "printf 'y\nn\n' | git add -p metrics.py > /dev/null"
run 'git commit -q -m "Compare normalized strings"'
run 'git show --stat --format=%s HEAD'
run 'git add README.md'
run 'git status --short'
cd "$LAB_DIR"

lab_end
