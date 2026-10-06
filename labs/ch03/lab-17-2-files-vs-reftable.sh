#!/usr/bin/env bash
# Lab 17.2 replay: the "files" ref backend versus reftable.
# Part A: one repository, copied and migrated, compared file by file and through plumbing.
# Part B: the failure scenario from setup-17-2-case-clash.sh (branch names that differ only in
# case, fetched on a case-insensitive filesystem) and its recovery.
# The names of reftable tables end in a random suffix, so listings pipe through sed to mask it.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch03 lab-17-2-files-vs-reftable
LAB_REPLAY=1 . "$LAB_SCRIPT_DIR/setup-17-2-case-clash.sh" || exit 1

snip 01-build
run 'git init --quiet files-repo'
run 'cd files-repo'
run "printf 'retry_limit = 3\\n' > config.toml"
run 'git add config.toml'
run 'git commit --quiet -m "Add service configuration"'
run 'git branch feature/batching'
run 'git tag -a v1.0.0 -m "Release 1.0.0"'
run 'cd ..'
note 'A byte-for-byte copy, then a migration of the copy to the other ref format:'
run 'cp -R files-repo reftable-repo'
run 'git -C reftable-repo refs migrate --ref-format=reftable'

snip 02-on-disk
run 'ls -A files-repo/.git'
run 'ls -A reftable-repo/.git'
run 'cat files-repo/.git/HEAD'
run 'cat reftable-repo/.git/HEAD'
run 'cat reftable-repo/.git/refs/heads'
run "ls reftable-repo/.git/reftable | sed -E 's/-[0-9a-f]{8}\\./-<random>./'"
run 'diff files-repo/.git/config reftable-repo/.git/config'

snip 03-plumbing
note 'Ask Git instead of the filesystem, and the two repositories give the same answers:'
run 'git -C files-repo for-each-ref'
run 'git -C reftable-repo for-each-ref'
run 'git -C files-repo symbolic-ref HEAD'
run 'git -C reftable-repo symbolic-ref HEAD'
run 'git -C reftable-repo reflog show main'
run 'git -C files-repo rev-parse --show-ref-format'
run 'git -C reftable-repo rev-parse --show-ref-format'

snip 04-by-hand
note 'A script that reads ref files by hand works in one repository only:'
run_rc 'cat files-repo/.git/refs/heads/main'
run_rc 'cat reftable-repo/.git/refs/heads/main'
note 'Writes go through the same commands in both:'
run 'git -C reftable-repo update-ref -m "start experiment" refs/heads/experiment main'
run 'git -C reftable-repo branch --list'

snip 05-failure
note 'Failure scenario. The server has branches Hotfix and hotfix; your clone uses the files format.'
run 'cd laptop'
run 'git rev-parse --show-ref-format'
run 'git branch --remotes'
run_rc 'git fetch origin'

snip 06-diagnosis
note 'What the server has:'
run 'git ls-remote origin "refs/heads/[Hh]otfix"'
note 'Ask this clone for each ref by name, and both names give the new value of Hotfix:'
run 'git rev-parse origin/Hotfix origin/hotfix'
note 'List the refs instead, and hotfix still has its value from before the fetch:'
run 'git for-each-ref "refs/remotes/origin/[Hh]otfix"'
note 'One loose file answers to both names. The listing takes the name hotfix from packed-refs:'
run 'find .git/refs/remotes -type f | sort'
run 'grep -i hotfix .git/packed-refs'
note 'Every further fetch fails on that contradiction:'
run_rc 'git fetch origin'

snip 07-recovery
note 'Recovery in this clone: a ref format that does not use one file per ref.'
run 'git refs migrate --ref-format=reftable'
run_rc 'git fetch origin'
run 'git for-each-ref refs/remotes/origin'

snip 08-verification
run 'git ls-remote origin "refs/heads/*"'
run 'git rev-parse --show-ref-format'
run_rc 'git fetch origin'

lab_end
