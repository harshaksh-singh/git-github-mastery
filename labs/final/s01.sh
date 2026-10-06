#!/usr/bin/env bash
# Final test, section 1 (Fundamentals): prediction items P1 and P2, diagram item G1 and
# interpretation item I1. The *-setup snippets are printed in assessments/final-test.md, the
# *-answer snippets only in answer-keys/final-test-answers.md.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin final s01

# ---- P1: an ignore rule that arrives after the file was tracked
snip p1-setup
run 'git init -q tracecollect'
run 'cd tracecollect'
run "printf 'boot ok\n' > service.log"
run "printf 'PORT=8080\n' > settings.env"
run 'git add .'
run 'git commit -q -m "Add service skeleton"'
run "printf '*.log\n*.env\n' > .gitignore"
run "printf 'boot ok\nretry 1\n' > service.log"
run "printf 'debug trace\n' > worker.log"
run 'git add .'
snip p1-answer
run 'git status --short'
run 'git status --short --ignored'
run_rc 'git check-ignore -v service.log worker.log'
cd "$LAB_DIR"

# ---- P2: what "git commit -a" takes
snip p2-setup
run 'git init -q seedbank'
run 'cd seedbank'
run "printf 'seed: 13\n' > seeds.yaml"
run "printf 'def split(rows):\n    return rows[:80], rows[80:]\n' > old_split.py"
run 'git add .'
run 'git commit -q -m "Add seeds and the split"'
run "printf 'seed: 42\n' > seeds.yaml"
run 'rm old_split.py'
run "printf 'def split(rows, ratio):\n    cut = int(len(rows) * ratio)\n    return rows[:cut], rows[cut:]\n' > new_split.py"
run 'git commit -q -a -m "Change the seed and the split"'
snip p2-answer
run 'git show --name-status --format=%s HEAD'
run 'git status --short'
cd "$LAB_DIR"

# ---- G1: one file in three places
snip g1-setup
run 'git init -q tilecache'
run 'cd tilecache'
run "printf 'ttl: 60\n' > cache.yaml"
run 'git add cache.yaml'
run 'git commit -q -m "Add cache settings"'
run "printf 'ttl: 120\n' > cache.yaml"
run 'git add cache.yaml'
run "printf 'ttl: 300\n' > cache.yaml"
run 'git commit -q -m "Raise the TTL"'
run "printf 'ttl: 600\n' > cache.yaml"
run 'git add cache.yaml'
run "printf 'ttl: 900\n' > cache.yaml"
run 'git restore --staged cache.yaml'
snip g1-answer
run 'git show HEAD:cache.yaml'
run 'git show :cache.yaml'
run 'cat cache.yaml'
run 'git status --short'
run 'git log --oneline'
cd "$LAB_DIR"

# ---- I1: a rename, as Git stores it
quiet 'git init -q dedupe'
cd dedupe || exit 1
printf 'import hashlib\n\ndef fingerprint(text):\n    norm = " ".join(text.lower().split())\n    return hashlib.sha256(norm.encode()).hexdigest()\n' > hashing.py
quiet 'git add . && git commit -q -m "Add text fingerprint"'
snip i1-transcript
run 'git mv hashing.py fingerprint.py'
run 'git status --short'
run 'git commit -q -m "Name the module after what it computes"'
run 'git log --oneline -- fingerprint.py'
run 'git log --oneline --follow -- fingerprint.py'
run 'git ls-tree HEAD~1'
run 'git ls-tree HEAD'
run 'git diff --name-status --no-renames HEAD~1 HEAD'
lab_end
