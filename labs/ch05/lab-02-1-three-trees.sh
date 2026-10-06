#!/usr/bin/env bash
# Replay of Lab 2.1: the three-trees prediction table. Every step changes at most one of
# working tree, index and HEAD; the helper show3 prints all three after each step.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/m02-setups.inc"
lab_begin ch05 lab-02-1-three-trees
m02_1_setup || exit 1
cd support-bot || exit 1

snip 01-start
run 'git log --oneline'
run 'show3() { echo "working tree: $(cat config/settings.yaml)"; echo "index:        $(git show :config/settings.yaml)"; echo "HEAD:         $(git show HEAD:config/settings.yaml)"; }'
run 'show3'

snip 02-steps-1-to-3
note 'Step 1'
run "echo 'top_k: 8' > config/settings.yaml"
run 'show3'
note 'Step 2'
run 'git add config/settings.yaml'
run 'show3'
note 'Step 3'
run "echo 'top_k: 12' > config/settings.yaml"
run 'show3'
run 'git status --short'

snip 03-steps-4-to-5
note 'Step 4'
run 'git commit -m "Raise top_k to 8"'
run 'show3'
note 'Step 5'
run 'git restore config/settings.yaml'
run 'show3'
run 'git status --short'

snip 04-steps-6-to-7
note 'Step 6'
run "echo 'top_k: 20' > config/settings.yaml"
run 'git add config/settings.yaml'
run 'show3'
note 'Step 7'
run 'git restore --staged config/settings.yaml'
run 'show3'
run 'git status --short'

snip 05-checkpoint
run 'git diff'
run 'git diff --cached'
run 'git diff HEAD'

snip 06-failure
note 'Failure scenario: discard the working tree copy. 20 is now in none of the three trees.'
run 'git restore config/settings.yaml'
run 'show3'
run 'git status --short'

snip 07-recovery
note 'Step 6 ran "git add" on that content, so a blob holds it. No ref or index entry points to it.'
run 'git fsck'
run 'git cat-file -p cbda4f9'
run 'git cat-file -p cbda4f9 > config/settings.yaml'

snip 08-verification
run 'show3'
run 'git status --short'
run 'git diff'

lab_end
