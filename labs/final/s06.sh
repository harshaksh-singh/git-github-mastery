#!/usr/bin/env bash
# Final test, section 6 (Undo): prediction items P1 to P3, diagram item G1 and interpretation
# item I1.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin final s06

# ---- P1: a mixed reset with other changes present
snip p1-setup
run 'git init -q throttle'
run 'cd throttle'
run "printf 'per_minute: 60\n' > limits.yaml"
run "printf 'burst: 10\n' > burst.yaml"
run "printf '# throttle\n' > README.md"
run 'git add . && git commit -q -m "Add rate limits"'
run "printf 'per_minute: 30\n' > limits.yaml"
run 'git commit -q -a -m "Tighten the limit"'
run "printf 'burst: 20\n' > burst.yaml"
run 'git add burst.yaml'
run "printf '# throttle\n\nSee limits.yaml.\n' > README.md"
run 'git reset -q HEAD~1'
snip p1-answer
run 'git status --short'
run 'git log --oneline'
run 'git diff --cached --stat'
run 'cat limits.yaml'
cd "$LAB_DIR"

# ---- P2: git restore reads the index unless told otherwise
snip p2-setup
run 'git init -q retries'
run 'cd retries'
run "printf 'attempts: 1\n' > retry.yaml"
run 'git add . && git commit -q -m "Add retry settings"'
run "printf 'attempts: 2\n' > retry.yaml"
run 'git add retry.yaml'
run "printf 'attempts: 3\n' > retry.yaml"
run 'git restore retry.yaml'
snip p2-answer-a
run 'cat retry.yaml'
run 'git status --short'
snip p2-setup-b
run 'git restore --source=HEAD --staged --worktree retry.yaml'
snip p2-answer-b
run 'cat retry.yaml'
run 'git status --short'
cd "$LAB_DIR"

# ---- P3: four dry runs of git clean
snip p3-setup
run 'git init -q trainrun'
run 'cd trainrun'
run "printf '*.ckpt\n' > .gitignore"
run "printf 'print(\"train\")\n' > train.py"
run 'git add . && git commit -q -m "Add the training script"'
run "printf 'try a lower learning rate\n' > notes.txt"
run 'mkdir scratch'
run "printf 'print(\"probe\")\n' > scratch/probe.py"
run "printf 'weights\n' > model.ckpt"
snip p3-answer
run 'git clean -n'
run 'git clean -n -d'
run 'git clean -n -d -x'
run 'git clean -n -d -X'
cd "$LAB_DIR"

# ---- G1: a merge, its revert, and a second merge
snip g1-setup
run 'git init -q faqbot'
run 'cd faqbot'
run "printf 'def answer(q):\n    return index.search(q)\n' > app.py"
run 'git add . && git commit -q -m "A: add the answer endpoint"'
run 'git switch -q -c feature/spellcheck'
run "printf 'def correct(q):\n    return q.replace(\"teh\", \"the\")\n' > spell.py"
run 'git add . && git commit -q -m "B: add spelling correction"'
run 'git switch -q main'
run 'git merge -q --no-ff -m "M1: merge feature/spellcheck" feature/spellcheck'
run 'git revert -m 1 --no-edit HEAD > /dev/null'
run 'git switch -q feature/spellcheck'
run "printf 'teh the\nrecieve receive\n' > corrections.txt"
run 'git add . && git commit -q -m "C: read corrections from a file"'
run 'git switch -q main'
run 'git merge -q --no-ff -m "M2: merge feature/spellcheck again" feature/spellcheck'
snip g1-answer
run 'git log --graph --oneline'
run 'git ls-files'
run 'git merge-base HEAD~1 feature/spellcheck | xargs git log -1 --format=%s'
cd "$LAB_DIR"

# ---- I1: a stash that does not apply cleanly
quiet 'git init -q webhook'
cd webhook || exit 1
printf 'retries: 3\ntimeout_s: 10\n' > delivery.yaml
quiet 'git add . && git commit -q -m "Add delivery settings"'
printf 'retries: 5\ntimeout_s: 10\n' > delivery.yaml
quiet 'git stash push -q -m "try five retries"'
printf 'retries: 4\ntimeout_s: 10\n' > delivery.yaml
quiet 'git commit -q -a -m "Use four retries"'
snip i1-transcript
run_rc 'git stash pop'
run 'git status --short'
run 'cat delivery.yaml'
run 'git stash list'
lab_end
