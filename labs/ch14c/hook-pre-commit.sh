#!/usr/bin/env bash
# Chapter 14C, section 14C.10: a worked pre-commit hook. It inspects the index, refuses a staged
# private key and a staged large file, and is skipped by --no-verify.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch14c hook-pre-commit

quiet 'git init trainer'
cd trainer || exit 1
quiet "printf 'import torch\n' > train.py && git add train.py && git commit -m 'Add training script'"
quiet "cp '$LAB_SCRIPT_DIR/files/pre-commit' .git/hooks/pre-commit"

snip 01-hook
run 'cat .git/hooks/pre-commit'
run 'chmod +x .git/hooks/pre-commit'

snip 02-blocked
note 'A deploy key and a 600 kB checkpoint are staged together with a real change:'
run "printf -- '-----BEGIN OPENSSH PRIVATE KEY-----\nnot-a-real-key\n-----END OPENSSH PRIVATE KEY-----\n' > deploy_key"
run 'head -c 600000 /dev/zero > checkpoint.pt'
run "printf 'import torch\nimport wandb\n' > train.py"
run 'git add .'
run_rc 'git commit -m "Log runs to the tracker"'
run 'git log --oneline'

snip 03-index-not-disk
note 'The hook reads the index. Deleting the files on disk is not enough:'
run 'rm deploy_key checkpoint.pt'
run_rc 'git commit -m "Log runs to the tracker"'
run 'git restore --staged deploy_key checkpoint.pt'
run_rc 'git commit -m "Log runs to the tracker"'

snip 04-no-verify
run "printf -- '-----BEGIN OPENSSH PRIVATE KEY-----\nnot-a-real-key\n-----END OPENSSH PRIVATE KEY-----\n' > deploy_key"
run 'git add deploy_key'
run_rc 'git commit --no-verify -m "Add deploy key"'
run 'git show --stat --format=%s HEAD'

lab_end
