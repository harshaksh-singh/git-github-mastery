#!/usr/bin/env bash
# Gate 4 (Recovery), prediction part. The pN-setup snippets are printed in the gate file, the
# pN-answer snippets only in the answer key.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin gates g4-predict

# ---- P1: two reflogs after a reset and a new commit
snip p1-setup
run 'git init -q embedder'
run 'cd embedder'
run 'git commit -q --allow-empty -m "Add embedder"'
run 'git commit -q --allow-empty -m "Add batching"'
run 'git commit -q --allow-empty -m "Add retry"'
run 'git switch -q -c spike/async'
run 'git commit -q --allow-empty -m "Try asyncio"'
run 'git switch -q main'
run 'git reset -q --hard HEAD~2'
run 'git commit -q --allow-empty -m "Add caching"'
snip p1-answer
run "git reflog --format='%gd %gs'"
run "git reflog show main --format='%gd %gs'"
run "git log -1 --format=%s 'main@{3}'"
run "git log -1 --format=%s 'HEAD@{3}'"
run 'git log -1 --format=%s ORIG_HEAD'
cd "$LAB_DIR"

# ---- P2: what fsck reports, and when
snip p2-setup
run 'git init -q ranker'
run 'cd ranker'
run 'git commit -q --allow-empty -m "Add ranker"'
run 'git switch -q -c spike/listwise'
run 'git commit -q --allow-empty -m "Listwise loss"'
run 'git commit -q --allow-empty -m "Listwise sampler"'
run 'git switch -q main'
run 'git branch -q -D spike/listwise'
snip p2-answer-a
run 'git fsck'
run 'git fsck --no-reflogs'
snip p2-setup-b
run 'git reflog expire --expire=now --all'
snip p2-answer-b
run 'git fsck'
run 'git fsck --unreachable'
run 'git gc -q --prune=now'
run 'git fsck --unreachable'
cd "$LAB_DIR"

# ---- P3: what a stash keeps of the index
snip p3-setup
run 'git init -q loader'
run 'cd loader'
run "printf 'workers: 2\n' > loader.yaml"
run "printf 'shuffle: true\n' > sampler.yaml"
run 'git add . && git commit -q -m "Add loader and sampler configuration"'
run "printf 'workers: 8\n' > loader.yaml"
run 'git add loader.yaml'
run "printf 'shuffle: false\n' > sampler.yaml"
run "printf 'profile the loader\n' > todo.txt"
run 'git stash -q'
snip p3-answer-a
run 'git status --short'
run "git show -s --format=%p 'stash@{0}' | wc -w | tr -d ' '"
snip p3-setup-b
run 'git stash pop -q'
snip p3-answer-b
run 'git status --short'
run 'git stash list'
cd "$LAB_DIR"

# ---- P4: -S counts occurrences, -G matches diff lines
snip p4-setup
run 'git init -q client'
run 'cd client'
run "printf 'retries = 3\ntimeout = 30\nbackoff = 2\nverify = true\n' > client.cfg"
run 'git add . && git commit -q -m "Add client settings"'
run "printf 'timeout = 30\nbackoff = 2\nverify = true\nretries = 3\n' > client.cfg"
run 'git commit -q -am "Move retries to the end"'
run "printf 'timeout = 30\nbackoff = 2\nverify = true\nretries = 5\n' > client.cfg"
run 'git commit -q -am "Retry five times"'
snip p4-answer
run "git log --format=%s -S'retries = 3'"
run "git log --format=%s -G'retries = 3'"
run "git log --format=%s -L4,4:client.cfg -s"
run "git log --format=%s -- client.cfg | wc -l | tr -d ' '"
lab_end
